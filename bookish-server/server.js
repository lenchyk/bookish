const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

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

async function hydrateBooks(books) {
    if (!books.length) {
        return books;
    }

    const ids = books.map((book) => book.id);

    const [authorRows] = await db.query(
        `SELECT ba.book_id, a.id, a.name
         FROM books_by_authors ba
         JOIN Authors a ON a.id = ba.author_id
         WHERE ba.book_id IN (?)`,
        [ids]
    );

    const [genreRows] = await db.query(
        `SELECT bg.book_id, g.id, g.name
         FROM book_genres bg
         JOIN Genres g ON g.id = bg.genre_id
         WHERE bg.book_id IN (?)`,
        [ids]
    );

    const [priceRows] = await db.query(
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
    );

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

async function hydrateCustomers(customers) {
    if (!customers.length) {
        return customers;
    }

    const currencyIds = [...new Set(customers.map((customer) => customer.currency_id).filter(Boolean))];
    let currenciesById = {};

    if (currencyIds.length) {
        const [currencyRows] = await db.query(
            `SELECT id, name, symbol, code FROM currencies WHERE id IN (?)`,
            [currencyIds]
        );
        currenciesById = Object.fromEntries(currencyRows.map((row) => [row.id, row]));
    }

    return customers.map((customer) => ({
        ...customer,
        currency: currenciesById[customer.currency_id] || null
    }));
}

async function hydrateOrders(orders) {
    if (!orders.length) {
        return orders;
    }

    const orderIds = orders.map((order) => order.id);
    const customerIds = [...new Set(orders.map((order) => order.customer_id).filter(Boolean))];
    const currencyIds = [...new Set(orders.map((order) => order.currency_id).filter(Boolean))];

    const [customerRows] = customerIds.length
        ? await db.query(`SELECT * FROM customers WHERE id IN (?)`, [customerIds])
        : [[]];
    const customers = await hydrateCustomers(customerRows);
    const customersById = Object.fromEntries(customers.map((customer) => [customer.id, customer]));

    const [currencyRows] = currencyIds.length
        ? await db.query(`SELECT id, name, symbol, code FROM currencies WHERE id IN (?)`, [currencyIds])
        : [[]];
    const currenciesById = Object.fromEntries(currencyRows.map((row) => [row.id, row]));

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
            ON bp.book_id = oi.book_id
           AND bp.currency_id = o.currency_id
         WHERE oi.order_id IN (?)`,
        [orderIds]
    );

    const bookIds = [...new Set(itemRows.map((item) => item.book_id).filter(Boolean))];
    const [bookRows] = bookIds.length
        ? await db.query(`SELECT * FROM books WHERE id IN (?)`, [bookIds])
        : [[]];
    const books = await hydrateBooks(bookRows);
    const booksById = Object.fromEntries(books.map((book) => [book.id, book]));

    const itemsByOrder = groupBy(itemRows, 'order_id');

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

function likeTerm(value) {
    return `%${String(value).replace(/[%_]/g, '\\$&')}%`;
}

// Get paginated books with authors, genres, and prices
app.get('/books', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const offset = (page - 1) * limit;

        const [books] = await db.query(
            'SELECT * FROM books ORDER BY id DESC LIMIT ? OFFSET ?',
            [limit, offset]
        );

        const [countResult] = await db.query(
            'SELECT COUNT(*) as total FROM books'
        );

        const data = await hydrateBooks(books);

        res.json({
            data,
            page,
            limit,
            total: countResult[0].total,
            hasMore: offset + books.length < countResult[0].total
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Something went wrong' });
    }
});

// Search books by title or author name
app.get('/books/search', async (req, res) => {
    console.time('total-search');

    try {
        const { query } = req.query;

        if (!query || !String(query).trim()) {
            return res.status(400).json({ error: 'Query is required' });
        }

        const searchTerm = likeTerm(String(query).trim());

        console.time('db-search');

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

        console.timeEnd('db-search');
        console.log(`Found ${rows.length} books`);

        res.json(await hydrateBooks(rows));
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Search failed' });
    } finally {
        console.timeEnd('total-search');
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

        const [book] = await hydrateBooks(rows);
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
        res.json(await hydrateCustomers(rows));
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

        const [customer] = await hydrateCustomers(rows);
        res.json(customer);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to load customer' });
    }
});

app.get('/orders', async (req, res) => {
    try {
        const [rows] = await db.query(
            'SELECT * FROM orders ORDER BY created_at DESC, id DESC'
        );
        res.json(await hydrateOrders(rows));
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

        const [order] = await hydrateOrders(rows);
        res.json(order);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to load order' });
    }
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
