const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const DEFAULT_PAGE_SIZE = 50;
const MAX_PAGE_SIZE = 100;

function loadEnv() {
  const envPath = path.join(__dirname, '.env');
  let contents;
  try {
    contents = fs.readFileSync(envPath, 'utf8');
  } catch {
    return;
  }

  for (const line of contents.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }
    const separator = trimmed.indexOf('=');
    if (separator === -1) {
      continue;
    }
    const key = trimmed.slice(0, separator).trim();
    let value = trimmed.slice(separator + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

loadEnv();

const app = express();

const PORT = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json());

const db = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'books'
});

function groupBy(rows, key) {
    return rows.reduce((acc, row) => {
        const id = row[key];
        (acc[id] ||= []).push(row);
        return acc;
    }, {});
}

function parsePagination(query, { defaultLimit = DEFAULT_PAGE_SIZE, maxLimit = MAX_PAGE_SIZE } = {}) {
    const page = Math.max(1, parseInt(query.page, 10) || 1);
    const rawLimit = parseInt(query.limit, 10);
    const limit = Math.min(
        maxLimit,
        Math.max(1, Number.isFinite(rawLimit) && rawLimit > 0 ? rawLimit : defaultLimit)
    );
    const offset = (page - 1) * limit;
    return { page, limit, offset };
}

function mapPrice(row) {
    return {
        id: row.id,
        book_id: row.book_id,
        price: row.price,
        created_at: row.created_at,
        currency: {
            id: row.currency_id,
            name: row.currency_name,
            symbol: row.currency_symbol,
            code: row.currency_code
        }
    };
}

async function attachBookRelations(books) {
    if (!books.length) {
        return books;
    }

    const ids = books.map((book) => book.id);

    const [[authorRows], [genreRows], [priceRows]] = await Promise.all([
        db.query(
            `SELECT ba.book_id, a.id, a.name
             FROM books_by_authors ba
             JOIN Authors a ON a.id = ba.author_id
             WHERE ba.book_id IN (?)`,
            [ids]
        ),
        db.query(
            `SELECT bg.book_id, g.id, g.name
             FROM book_genres bg
             JOIN Genres g ON g.id = bg.genre_id
             WHERE bg.book_id IN (?)`,
            [ids]
        ),
        db.query(
            `SELECT
                bp.id,
                bp.book_id,
                bp.price,
                bp.created_at,
                c.id AS currency_id,
                c.name AS currency_name,
                c.symbol AS currency_symbol,
                c.code AS currency_code
             FROM book_prices bp
             JOIN currencies c ON c.id = bp.currency_id
             WHERE bp.book_id IN (?)`,
            [ids]
        )
    ]);

    const authorsByBook = groupBy(authorRows, 'book_id');
    const genresByBook = groupBy(genreRows, 'book_id');
    const pricesByBook = groupBy(priceRows, 'book_id');

    return books.map((book) => ({
        ...book,
        authors: (authorsByBook[book.id] || []).map(({ id, name }) => ({ id, name })),
        genres: (genresByBook[book.id] || []).map(({ id, name }) => ({ id, name })),
        prices: (pricesByBook[book.id] || []).map(mapPrice)
    }));
}

async function attachCustomerRelations(customers, currenciesById = null) {
    if (!customers.length) {
        return customers;
    }

    let resolvedCurrencies = currenciesById;

    if (!resolvedCurrencies) {
        const currencyIds = [...new Set(customers.map((customer) => customer.currency_id).filter(Boolean))];
        resolvedCurrencies = {};

        if (currencyIds.length) {
            const [currencyRows] = await db.query(
                `SELECT id, name, symbol, code FROM currencies WHERE id IN (?)`,
                [currencyIds]
            );
            resolvedCurrencies = Object.fromEntries(currencyRows.map((row) => [row.id, row]));
        }
    }

    return customers.map((customer) => ({
        ...customer,
        currency: resolvedCurrencies[customer.currency_id] || null
    }));
}

async function attachOrderRelations(orders, { includeItems = true } = {}) {
    if (!orders.length) {
        return orders;
    }

    const orderIds = orders.map((order) => order.id);
    const customerIds = [...new Set(orders.map((order) => order.customer_id).filter(Boolean))];
    const currencyIds = [...new Set(orders.map((order) => order.currency_id).filter(Boolean))];

    const [[customerRows], [currencyRows]] = await Promise.all([
        customerIds.length
            ? db.query(`SELECT * FROM customers WHERE id IN (?)`, [customerIds])
            : Promise.resolve([[]]),
        currencyIds.length
            ? db.query(`SELECT id, name, symbol, code FROM currencies WHERE id IN (?)`, [currencyIds])
            : Promise.resolve([[]])
    ]);

    const currenciesById = Object.fromEntries(currencyRows.map((row) => [row.id, row]));
    const customers = await attachCustomerRelations(customerRows, currenciesById);
    const customersById = Object.fromEntries(customers.map((customer) => [customer.id, customer]));

    let itemsByOrder = {};

    if (includeItems) {
        // Pick the latest book_prices row per (book_id, currency_id) so history
        // rows do not multiply order_items in the response.
        const [itemRows] = await db.query(
            `SELECT
                oi.id,
                oi.order_id,
                oi.book_id,
                oi.amount,
                bp.price AS unit_price
             FROM order_items oi
             JOIN orders o ON o.id = oi.order_id
             LEFT JOIN book_prices bp
                ON bp.id = (
                    SELECT bp2.id
                    FROM book_prices bp2
                    WHERE bp2.book_id = oi.book_id
                      AND bp2.currency_id = o.currency_id
                    ORDER BY bp2.created_at DESC, bp2.id DESC
                    LIMIT 1
                )
             WHERE oi.order_id IN (?)`,
            [orderIds]
        );

        const bookIds = [...new Set(itemRows.map((item) => item.book_id).filter(Boolean))];
        const [bookRows] = bookIds.length
            ? await db.query(`SELECT * FROM books WHERE id IN (?)`, [bookIds])
            : [[]];
        const books = await attachBookRelations(bookRows);
        const booksById = Object.fromEntries(books.map((book) => [book.id, book]));

        itemsByOrder = groupBy(itemRows, 'order_id');

        return orders.map((order) => {
            const items = (itemsByOrder[order.id] || []).map((item) => ({
                id: item.id,
                order_id: item.order_id,
                book_id: item.book_id,
                amount: item.amount,
                unit_price: item.unit_price,
                book: booksById[item.book_id] || null
            }));

            return {
                ...order,
                customer: customersById[order.customer_id] || null,
                currency: currenciesById[order.currency_id] || null,
                items
            };
        });
    }

    return orders.map((order) => ({
        ...order,
        customer: customersById[order.customer_id] || null,
        currency: currenciesById[order.currency_id] || null,
        items: []
    }));
}

function likeTerm(value) {
    return `%${String(value).replace(/[%_]/g, '\\$&')}%`;
}

// Get paginated books with authors, genres, and prices
app.get('/books', async (req, res) => {
    try {
        const { page, limit, offset } = parsePagination(req.query);

        const [[books], [countResult]] = await Promise.all([
            db.query(
                'SELECT * FROM books ORDER BY id DESC LIMIT ? OFFSET ?',
                [limit, offset]
            ),
            db.query('SELECT COUNT(*) as total FROM books')
        ]);

        const data = await attachBookRelations(books);
        const total = countResult[0].total;

        res.json({
            data,
            page,
            limit,
            total,
            hasMore: offset + books.length < total
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Something went wrong' });
    }
});

// Search books by title or author name
app.get('/books/search', async (req, res) => {
    try {
        const { query } = req.query;

        if (!query || !String(query).trim()) {
            return res.status(400).json({ error: 'Query is required' });
        }

        const searchTerm = likeTerm(String(query).trim());

        const [rows] = await db.query(
            `SELECT DISTINCT b.*
             FROM books b
             LEFT JOIN books_by_authors ba ON ba.book_id = b.id
             LEFT JOIN Authors a ON a.id = ba.author_id
             WHERE b.title LIKE ?
                OR a.name LIKE ?
             ORDER BY b.id DESC
             LIMIT 100`,
            [searchTerm, searchTerm]
        );

        res.json(await attachBookRelations(rows));
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Search failed' });
    }
});

app.get('/books/:id', async (req, res) => {
    try {
        const bookId = req.params.id;
        const [rows] = await db.query(
            'SELECT * FROM books WHERE id = ?',
            [bookId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        const [book] = await attachBookRelations(rows);
        res.json(book);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Something went wrong' });
    }
});

app.post('/books', async (req, res) => {
    try {
        const title = req.body.title;
        const amount = req.body.amount ?? null;
        const publishedYear = req.body.published_year ?? req.body.publishedYear ?? null;
        const pagesCount = req.body.pages_count ?? req.body.pagesCount ?? null;
        const typeOfBinding = req.body.type_of_binding ?? req.body.typeOfBinding ?? null;
        const description = req.body.description ?? null;

        if (!title) {
            return res.status(400).json({ error: 'Title is required' });
        }

        const [result] = await db.query(
            `INSERT INTO books (title, amount, published_year, pages_count, type_of_binding, description)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [title, amount, publishedYear, pagesCount, typeOfBinding, description]
        );

        res.status(201).json({
            success: true,
            id: result.insertId
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to create book' });
    }
});

app.put('/books/:id', async (req, res) => {
    try {
        const bookId = req.params.id;
        const title = req.body.title ?? null;
        const amount = req.body.amount ?? null;
        const publishedYear = req.body.published_year ?? req.body.publishedYear ?? null;
        const pagesCount = req.body.pages_count ?? req.body.pagesCount ?? null;
        const typeOfBinding = req.body.type_of_binding ?? req.body.typeOfBinding ?? null;
        const description = req.body.description ?? null;

        const [result] = await db.query(
            `UPDATE books
             SET
                title = COALESCE(?, title),
                amount = COALESCE(?, amount),
                published_year = COALESCE(?, published_year),
                pages_count = COALESCE(?, pages_count),
                type_of_binding = COALESCE(?, type_of_binding),
                description = COALESCE(?, description)
             WHERE id = ?`,
            [title, amount, publishedYear, pagesCount, typeOfBinding, description, bookId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        res.json({
            success: true,
            message: 'Book updated'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Update failed' });
    }
});

app.delete('/books/:id', async (req, res) => {
    try {
        const bookId = req.params.id;
        const [result] = await db.query(
            'DELETE FROM books WHERE id = ?',
            [bookId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        res.json({
            success: true,
            message: 'Book deleted'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Delete failed' });
    }
});

app.get('/currencies', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT id, name, symbol, code FROM currencies ORDER BY id');
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to load currencies' });
    }
});

app.get('/customers', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM customers ORDER BY id');
        res.json(await attachCustomerRelations(rows));
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to load customers' });
    }
});

app.get('/customers/:id', async (req, res) => {
    try {
        const [rows] = await db.query(
            'SELECT * FROM customers WHERE id = ?',
            [req.params.id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        const [customer] = await attachCustomerRelations(rows);
        res.json(customer);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to load customer' });
    }
});

app.get('/orders', async (req, res) => {
    try {
        const { page, limit, offset } = parsePagination(req.query);

        const [[rows], [countResult]] = await Promise.all([
            db.query(
                'SELECT * FROM orders ORDER BY created_at DESC, id DESC LIMIT ? OFFSET ?',
                [limit, offset]
            ),
            db.query('SELECT COUNT(*) as total FROM orders')
        ]);

        // List payload: customer + currency only. Full items/books live on GET /orders/:id.
        const data = await attachOrderRelations(rows, { includeItems: false });
        const total = countResult[0].total;

        res.json({
            data,
            page,
            limit,
            total,
            hasMore: offset + rows.length < total
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to load orders' });
    }
});

app.get('/orders/:id', async (req, res) => {
    try {
        const [rows] = await db.query(
            'SELECT * FROM orders WHERE id = ?',
            [req.params.id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const [order] = await attachOrderRelations(rows, { includeItems: true });
        res.json(order);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to load order' });
    }
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
