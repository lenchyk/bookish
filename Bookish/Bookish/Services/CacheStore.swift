//
//  CacheStore.swift
//  Bookish
//
//  Created by Soroka, Olena on 30.08.2026.
//

import Foundation
import SwiftData

struct CachedPage<T> {
  let items: [T]
  let hasMore: Bool
}

@ModelActor
actor CacheStore {
  func upsertBooks(_ books: [Book]) throws {
    try upsertBooks(books, save: true)
  }

  func upsertCustomers(_ customers: [Customer]) throws {
    for customer in customers {
      _ = try upsertCustomer(customer)
    }
    try modelContext.save()
  }

  func upsertOrders(_ orders: [Order]) throws {
    let nestedBooks = orders.flatMap { $0.items.compactMap(\.book) }
    try upsertBooks(nestedBooks, save: false)

    for order in orders {
      try upsertOrder(order, save: false)
    }
    try modelContext.save()
  }

  func upsertOrder(_ order: Order) throws {
    let nestedBooks = order.items.compactMap(\.book)
    try upsertBooks(nestedBooks, save: false)
    try upsertOrder(order, save: true)
  }

  func deleteBook(id: Int) throws {
    if let cached = try fetchBook(id: id) {
      modelContext.delete(cached)
      try modelContext.save()
    }
  }

  func booksPage(page: Int, limit: Int = BookishPaging.pageSize) throws -> CachedPage<Book> {
    let offset = max(page - 1, 0) * limit
    var descriptor = FetchDescriptor<BookCache>(
      sortBy: [SortDescriptor(\.id, order: .reverse)]
    )
    descriptor.fetchOffset = offset
    descriptor.fetchLimit = limit + 1
    let fetched = try modelContext.fetch(descriptor)
    let hasMore = fetched.count > limit
    let items = (hasMore ? Array(fetched.prefix(limit)) : fetched).map(Book.init(cache:))
    return CachedPage(items: items, hasMore: hasMore)
  }

  func book(id: Int) throws -> Book? {
    try fetchBook(id: id).map(Book.init(cache:))
  }

  func searchBooks(query: String, limit: Int = BookishPaging.pageSize) throws -> [Book] {
    let q = query
    var titleDescriptor = FetchDescriptor<BookCache>(
      predicate: #Predicate { $0.title.localizedStandardContains(q) },
      sortBy: [SortDescriptor(\.id, order: .reverse)]
    )
    titleDescriptor.fetchLimit = limit
    var matches = try modelContext.fetch(titleDescriptor)

    let authorDescriptor = FetchDescriptor<AuthorCache>(
      predicate: #Predicate { $0.name.localizedStandardContains(q) }
    )
    let authors = try modelContext.fetch(authorDescriptor)
    var existingIDs = Set(matches.map(\.id))
    for author in authors {
      for book in author.books where existingIDs.insert(book.id).inserted {
        matches.append(book)
      }
    }

    matches.sort { $0.id > $1.id }
    return Array(matches.prefix(limit)).map(Book.init(cache:))
  }

  func customers() throws -> [Customer] {
    let descriptor = FetchDescriptor<CustomerCache>(
      sortBy: [SortDescriptor(\.id)]
    )
    return try modelContext.fetch(descriptor).map(Customer.init(cache:))
  }

  func orders() throws -> [Order] {
    let descriptor = FetchDescriptor<OrderCache>(
      sortBy: [SortDescriptor(\.id, order: .reverse)]
    )
    return try modelContext.fetch(descriptor).map(Order.init(cache:))
  }

  func order(id: Int) throws -> Order? {
    try fetchOrder(id: id).map(Order.init(cache:))
  }

  // MARK: - Upsert

  private func upsertBooks(_ books: [Book], save: Bool) throws {
    guard !books.isEmpty else { return }

    var booksByID = Dictionary(
      uniqueKeysWithValues: try fetchBooks(ids: books.map(\.id)).map { ($0.id, $0) }
    )
    var authorsByID = Dictionary(
      uniqueKeysWithValues: try fetchAuthors(ids: books.flatMap { $0.authors.map(\.id) }).map { ($0.id, $0) }
    )
    var genresByID = Dictionary(
      uniqueKeysWithValues: try fetchGenres(ids: books.flatMap { $0.genres.map(\.id) }).map { ($0.id, $0) }
    )
    var currenciesByID = Dictionary(
      uniqueKeysWithValues: try fetchCurrencies(
        ids: books.flatMap { $0.prices.compactMap(\.currency?.id) }
      ).map { ($0.id, $0) }
    )
    var pricesByID = Dictionary(
      uniqueKeysWithValues: try fetchPrices(ids: books.flatMap { $0.prices.map(\.id) }).map { ($0.id, $0) }
    )

    for book in books {
      let authors = book.authors.map { author in
        upsertAuthor(author, into: &authorsByID)
      }
      let genres = book.genres.map { genre in
        upsertGenre(genre, into: &genresByID)
      }
      let prices = book.prices.map { price in
        upsertPrice(price, currencies: &currenciesByID, prices: &pricesByID)
      }

      let cached: BookCache
      if let existing = booksByID[book.id] {
        existing.update(from: book)
        cached = existing
      } else {
        cached = BookCache(book: book)
        modelContext.insert(cached)
        booksByID[book.id] = cached
      }

      cached.authors = authors
      cached.genres = genres
      cached.prices = prices
    }

    if save {
      try modelContext.save()
    }
  }

  private func upsertOrder(_ order: Order, save: Bool) throws {
    let customer = try order.customer.map { try upsertCustomer($0) }
    let currency = try order.currency.map { try upsertCurrency($0) }

    let cached: OrderCache
    if let existing = try fetchOrder(id: order.id) {
      existing.update(from: order, customer: customer, currency: currency)
      cached = existing
    } else {
      cached = OrderCache(id: order.id)
      cached.update(from: order, customer: customer, currency: currency)
      modelContext.insert(cached)
    }

    cached.items = try upsertOrderItems(order.items)

    if save {
      try modelContext.save()
    }
  }

  private func upsertAuthor(
    _ author: Author,
    into authorsByID: inout [Int: AuthorCache]
  ) -> AuthorCache {
    if let existing = authorsByID[author.id] {
      existing.update(from: author)
      return existing
    }
    let cache = AuthorCache(id: author.id, name: author.name)
    modelContext.insert(cache)
    authorsByID[author.id] = cache
    return cache
  }

  private func upsertGenre(
    _ genre: Genre,
    into genresByID: inout [Int: GenreCache]
  ) -> GenreCache {
    if let existing = genresByID[genre.id] {
      existing.update(from: genre)
      return existing
    }
    let cache = GenreCache(id: genre.id, name: genre.name)
    modelContext.insert(cache)
    genresByID[genre.id] = cache
    return cache
  }

  private func upsertPrice(
    _ price: BookPrice,
    currencies: inout [Int: CurrencyCache],
    prices: inout [Int: BookPriceCache]
  ) -> BookPriceCache {
    let currency: CurrencyCache?
    if let nested = price.currency {
      if let existing = currencies[nested.id] {
        existing.update(from: nested)
        currency = existing
      } else {
        let created = CurrencyCache(
          id: nested.id,
          name: nested.name,
          symbol: nested.symbol,
          code: nested.code
        )
        modelContext.insert(created)
        currencies[nested.id] = created
        currency = created
      }
    } else {
      currency = nil
    }

    if let existing = prices[price.id] {
      existing.update(from: price, currency: currency)
      return existing
    }

    let cache = BookPriceCache(
      id: price.id,
      price: price.price,
      createdAt: price.createdAt,
      currency: currency
    )
    modelContext.insert(cache)
    prices[price.id] = cache
    return cache
  }

  private func upsertCustomer(_ customer: Customer) throws -> CustomerCache {
    let currency = try customer.currency.map { try upsertCurrency($0) }
    if let existing = try fetchCustomer(id: customer.id) {
      existing.update(from: customer, currency: currency)
      return existing
    }
    let cache = CustomerCache(
      id: customer.id,
      fullname: customer.fullname,
      email: customer.email,
      address: customer.address,
      currency: currency
    )
    modelContext.insert(cache)
    return cache
  }

  private func upsertCurrency(_ currency: Currency) throws -> CurrencyCache {
    if let existing = try fetchCurrency(id: currency.id) {
      existing.update(from: currency)
      return existing
    }
    let cache = CurrencyCache(
      id: currency.id,
      name: currency.name,
      symbol: currency.symbol,
      code: currency.code
    )
    modelContext.insert(cache)
    return cache
  }

  private func upsertOrderItems(_ items: [OrderItem]) throws -> [OrderItemCache] {
    try items.map { item in
      let book: BookCache?
      if let nested = item.book {
        book = try fetchBook(id: nested.id)
      } else if let bookId = item.bookId {
        book = try fetchBook(id: bookId)
      } else {
        book = nil
      }

      if let existing = try fetchOrderItem(id: item.id) {
        existing.update(from: item, book: book)
        return existing
      }

      let cache = OrderItemCache(
        id: item.id,
        amount: item.amount,
        unitPrice: item.unitPrice,
        book: book
      )
      modelContext.insert(cache)
      return cache
    }
  }

  // MARK: - Fetches

  private func fetchBooks(ids: [Int]) throws -> [BookCache] {
    let targetIDs = Array(Set(ids))
    guard !targetIDs.isEmpty else { return [] }
    return try modelContext.fetch(
      FetchDescriptor<BookCache>(predicate: #Predicate { targetIDs.contains($0.id) })
    )
  }

  private func fetchAuthors(ids: [Int]) throws -> [AuthorCache] {
    let targetIDs = Array(Set(ids))
    guard !targetIDs.isEmpty else { return [] }
    return try modelContext.fetch(
      FetchDescriptor<AuthorCache>(predicate: #Predicate { targetIDs.contains($0.id) })
    )
  }

  private func fetchGenres(ids: [Int]) throws -> [GenreCache] {
    let targetIDs = Array(Set(ids))
    guard !targetIDs.isEmpty else { return [] }
    return try modelContext.fetch(
      FetchDescriptor<GenreCache>(predicate: #Predicate { targetIDs.contains($0.id) })
    )
  }

  private func fetchCurrencies(ids: [Int]) throws -> [CurrencyCache] {
    let targetIDs = Array(Set(ids))
    guard !targetIDs.isEmpty else { return [] }
    return try modelContext.fetch(
      FetchDescriptor<CurrencyCache>(predicate: #Predicate { targetIDs.contains($0.id) })
    )
  }

  private func fetchPrices(ids: [Int]) throws -> [BookPriceCache] {
    let targetIDs = Array(Set(ids))
    guard !targetIDs.isEmpty else { return [] }
    return try modelContext.fetch(
      FetchDescriptor<BookPriceCache>(predicate: #Predicate { targetIDs.contains($0.id) })
    )
  }

  private func fetchBook(id: Int) throws -> BookCache? {
    let targetId = id
    var descriptor = FetchDescriptor<BookCache>(
      predicate: #Predicate { $0.id == targetId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func fetchOrder(id: Int) throws -> OrderCache? {
    let targetId = id
    var descriptor = FetchDescriptor<OrderCache>(
      predicate: #Predicate { $0.id == targetId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func fetchCustomer(id: Int) throws -> CustomerCache? {
    let targetId = id
    var descriptor = FetchDescriptor<CustomerCache>(
      predicate: #Predicate { $0.id == targetId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func fetchCurrency(id: Int) throws -> CurrencyCache? {
    let targetId = id
    var descriptor = FetchDescriptor<CurrencyCache>(
      predicate: #Predicate { $0.id == targetId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func fetchOrderItem(id: Int) throws -> OrderItemCache? {
    let targetId = id
    var descriptor = FetchDescriptor<OrderItemCache>(
      predicate: #Predicate { $0.id == targetId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}
