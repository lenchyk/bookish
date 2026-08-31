//
//  BookishApplicationServiceTests.swift
//  BookishTests
//
//  Created by Soroka, Olena on 10.07.2026.
//

import Testing
import Foundation
import SwiftData

@testable import Bookish

final class MockBooksAPIClient: APIClientProtocol {
  var bookToReturn: Book?
  var booksResponseToReturn: BooksResponse?
  var customersToReturn: [Customer] = []
  var ordersToReturn: [Order] = []
  var orderToReturn: Order?
  var searchResults: [Book] = []
  var errorToThrow: Error?
  var searchError: Error?
  var deletedIDs: [Int] = []

  func getBook(by id: Int) async throws -> Book {
    if let errorToThrow { throw errorToThrow }
    guard let bookToReturn else {
      throw APIError.httpStatus(404)
    }
    return bookToReturn
  }

  func getBooks(page: Int, limit: Int) async throws -> BooksResponse {
    if let errorToThrow { throw errorToThrow }
    guard let booksResponseToReturn else {
      throw APIError.httpStatus(500)
    }
    return booksResponseToReturn
  }

  func updateBook(id: Int, update: BookUpdate) async throws {
    if let errorToThrow { throw errorToThrow }
  }

  func search(query: String) async throws -> [Book] {
    if let searchError { throw searchError }
    if let errorToThrow { throw errorToThrow }
    return searchResults
  }

  func deleteBook(id: Int) async throws {
    if let errorToThrow { throw errorToThrow }
    deletedIDs.append(id)
  }

  func getCustomers() async throws -> [Customer] {
    if let errorToThrow { throw errorToThrow }
    return customersToReturn
  }

  func getOrders() async throws -> [Order] {
    if let errorToThrow { throw errorToThrow }
    return ordersToReturn
  }

  func getOrder(by id: Int) async throws -> Order {
    if let errorToThrow { throw errorToThrow }
    guard let orderToReturn else {
      throw APIError.httpStatus(404)
    }
    return orderToReturn
  }
}

@MainActor
struct BookishApplicationServiceTests {
  @Test
  func `getBook stores a book in cache`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()
    let expected = sampleBook(id: 1, title: "Swift", price: 25)
    api.bookToReturn = expected

    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )

    _ = try await sut.getBook(by: 1)

    let cached = try await sut.getCachedBook(id: 1)

    #expect(cached?.id == expected.id)
    #expect(cached?.title == expected.title)
    #expect(cached?.authors == expected.authors)
    #expect(cached?.genres == expected.genres)
    #expect(cached?.prices.first?.price == expected.prices.first?.price)
    #expect(cached?.prices.first?.currency == expected.prices.first?.currency)
  }

  @Test
  func `getBooks stores multiple books in cache`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()

    let books = [
      sampleBook(id: 1, title: "Swift", price: 20),
      sampleBook(id: 2, title: "Clean Code", price: 30, authorName: "Robert Martin")
    ]

    api.booksResponseToReturn = BooksResponse(
      data: books,
      page: 1,
      limit: 50,
      total: 2,
      hasMore: false
    )

    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )

    _ = try await sut.getBooks(page: 1)

    let cachedBooks = try await sut.getCachedBooks(page: 1)

    #expect(cachedBooks.items.count == 2)
    #expect(cachedBooks.items.map(\.id).sorted() == [1, 2])
    #expect(cachedBooks.hasMore == false)
  }

  @Test
  func `getBook updates cache`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()
    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )

    api.bookToReturn = sampleBook(id: 1, title: "Old title", price: 20)
    _ = try await sut.getBook(by: 1)

    api.bookToReturn = sampleBook(id: 1, title: "New title", price: 50)
    _ = try await sut.getBook(by: 1)

    let cached = try await sut.getCachedBook(id: 1)

    #expect(cached?.title == "New title")
    #expect(cached?.prices.first?.price == Decimal(50))

    let allBooks = try await sut.getCachedBooks(page: 1)
    #expect(allBooks.items.count == 1)
  }

  @Test
  func `getBooks falls back to a paged cache`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()
    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )

    api.booksResponseToReturn = BooksResponse(
      data: [sampleBook(id: 1, title: "Swift", price: 20)],
      page: 1,
      limit: 50,
      total: 1,
      hasMore: false
    )
    _ = try await sut.getBooks(page: 1)

    api.errorToThrow = APIError.httpStatus(500)
    let fallback = try await sut.getBooks(page: 1)

    #expect(fallback.data.count == 1)
    #expect(fallback.data.first?.title == "Swift")
  }

  @Test
  func `search does not persist hits and falls back to cache`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()
    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )

    api.booksResponseToReturn = BooksResponse(
      data: [sampleBook(id: 1, title: "Swift Programming", price: 20)],
      page: 1,
      limit: 50,
      total: 1,
      hasMore: false
    )
    _ = try await sut.getBooks(page: 1)

    api.searchResults = [sampleBook(id: 99, title: "Transient Search Hit", price: 9)]
    let live = try await sut.search(query: "Transient")
    #expect(live.first?.id == 99)
    #expect(try await sut.getCachedBook(id: 99) == nil)

    api.searchError = APIError.httpStatus(500)
    let cached = try await sut.search(query: "Swift")
    #expect(cached.map(\.id) == [1])
  }

  @Test
  func `deleteBook removes the row from cache and the list ViewModel`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()
    let book = sampleBook(id: 1, title: "Swift", price: 20)
    api.bookToReturn = book

    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )
    _ = try await sut.getBook(by: 1)

    let viewModel = BooksListViewModel(service: sut)
    viewModel.books = [book]

    try await sut.deleteBook(id: 1)
    viewModel.removeBook(id: 1)

    #expect(api.deletedIDs == [1])
    #expect(try await sut.getCachedBook(id: 1) == nil)
    #expect(viewModel.books.isEmpty)
  }

  @Test
  func `decodes book JSON from the new schema`() throws {
    let json = """
    {
      "id": 1,
      "title": "Swift",
      "amount": 4,
      "published_year": 2024,
      "pages_count": 320,
      "type_of_binding": "hardcover",
      "description": "A programming book",
      "authors": [{ "id": 9, "name": "Apple" }],
      "genres": [{ "id": 3, "name": "Programming" }],
      "prices": [{
        "id": 11,
        "book_id": 1,
        "price": "25.50",
        "created_at": "2026-05-23T10:00:00.000Z",
        "currency": {
          "id": 1,
          "name": "US Dollar",
          "symbol": "$",
          "code": "USD"
        }
      }]
    }
    """.data(using: .utf8)!

    let book = try APIJSON.decoder.decode(Book.self, from: json)

    #expect(book.title == "Swift")
    #expect(book.amount == 4)
    #expect(book.publishedYear == 2024)
    #expect(book.pagesCount == 320)
    #expect(book.typeOfBinding == "hardcover")
    #expect(book.authors.first?.name == "Apple")
    #expect(book.genres.first?.name == "Programming")
    #expect(book.prices.first?.price == Decimal(string: "25.50"))
    #expect(book.prices.first?.currency?.code == "USD")
    #expect(book.formattedPrice.contains("25.50") || book.formattedPrice.contains("$"))
  }

  @Test
  func `missing price stays unavailable instead of decoding as zero`() throws {
    let json = """
    {
      "id": 1,
      "title": "Swift",
      "authors": [],
      "genres": [],
      "prices": [{
        "id": 11,
        "book_id": 1,
        "price": null,
        "currency": {
          "id": 1,
          "name": "US Dollar",
          "symbol": "$",
          "code": "USD"
        }
      }]
    }
    """.data(using: .utf8)!

    let book = try APIJSON.decoder.decode(Book.self, from: json)

    #expect(book.prices.first?.price == nil)
    #expect(book.primaryPrice == nil)
    #expect(book.formattedPrice == "Price unavailable")
  }

  @Test
  func `primary price uses the first amount that has a value`() {
    let usd = Currency(id: 1, name: "US Dollar", symbol: "$", code: "USD")
    let first = BookPrice(
      id: 1,
      bookId: 1,
      price: Decimal(10),
      currency: usd
    )
    let second = BookPrice(
      id: 2,
      bookId: 1,
      price: Decimal(40),
      currency: usd
    )
    let book = Book(id: 1, title: "Swift", prices: [first, second])
    #expect(book.primaryPrice?.id == 1)
    #expect(book.primaryPrice?.price == Decimal(10))
  }

  @Test
  func `decodes order using order currency not customer currency`() throws {
    let json = """
    {
      "id": 7,
      "description": "Gift order",
      "total_price": "40.00",
      "created_at": "2026-05-23T10:00:00.000Z",
      "status": "paid",
      "customer": {
        "id": 2,
        "fullname": "Ada Lovelace",
        "email": "ada@example.com",
        "address": "London",
        "currency": {
          "id": 2,
          "name": "Euro",
          "symbol": "€",
          "code": "EUR"
        }
      },
      "currency": {
        "id": 1,
        "name": "US Dollar",
        "symbol": "$",
        "code": "USD"
      },
      "items": [{
        "id": 15,
        "book_id": 1,
        "amount": 2,
        "unit_price": "20.00",
        "book": {
          "id": 1,
          "title": "Swift",
          "authors": [],
          "genres": [],
          "prices": []
        }
      }]
    }
    """.data(using: .utf8)!

    let order = try APIJSON.decoder.decode(Order.self, from: json)

    #expect(order.currency?.code == "USD")
    #expect(order.customer?.currency?.code == "EUR")
    #expect(order.displayTotal == Decimal(string: "40.00"))
    #expect(order.computedTotal == Decimal(string: "40.00"))
    #expect(order.items.first?.amount == 2)
    #expect(order.formattedTotal.contains("$") || order.formattedTotal.contains("40"))
  }

  @Test
  func `order item price resolves from book_prices in the order currency`() throws {
    let json = """
    {
      "id": 8,
      "total_price": null,
      "status": "paid",
      "currency": {
        "id": 1,
        "name": "US Dollar",
        "symbol": "$",
        "code": "USD"
      },
      "customer": {
        "id": 2,
        "fullname": "Ada Lovelace",
        "currency": {
          "id": 2,
          "name": "Euro",
          "symbol": "€",
          "code": "EUR"
        }
      },
      "items": [{
        "id": 15,
        "book_id": 1,
        "amount": 2,
        "book": {
          "id": 1,
          "title": "Swift",
          "authors": [],
          "genres": [],
          "prices": [
            {
              "id": 21,
              "book_id": 1,
              "price": "18.00",
              "currency": { "id": 2, "name": "Euro", "symbol": "€", "code": "EUR" }
            },
            {
              "id": 22,
              "book_id": 1,
              "price": "20.00",
              "currency": { "id": 1, "name": "US Dollar", "symbol": "$", "code": "USD" }
            }
          ]
        }
      }]
    }
    """.data(using: .utf8)!

    let order = try APIJSON.decoder.decode(Order.self, from: json)
    let item = try #require(order.items.first)

    #expect(item.unitPrice == nil)
    #expect(item.resolvedUnitPrice(currency: order.currency) == Decimal(string: "20.00"))
    #expect(item.lineTotal(currency: order.currency) == Decimal(string: "40.00"))
    #expect(order.computedTotal == Decimal(string: "40.00"))
    #expect(order.displayTotal == Decimal(string: "40.00"))
    #expect(item.formattedUnitPrice(currency: order.currency).contains("20") || item.formattedUnitPrice(currency: order.currency).contains("$"))
  }

  @Test
  func `getOrders caches orders and items`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()

    let usd = Currency(id: 1, name: "US Dollar", symbol: "$", code: "USD")
    let order = Order(
      id: 7,
      customer: Customer(
        id: 2,
        fullname: "Ada Lovelace",
        email: "ada@example.com",
        address: "London",
        currency: usd
      ),
      currency: usd,
      description: "Gift order",
      totalPrice: Decimal(40),
      createdAt: Date(timeIntervalSince1970: 1_700_000_000),
      status: "paid",
      items: [
        OrderItem(
          id: 15,
          bookId: 1,
          book: sampleBook(id: 1, title: "Swift", price: 20),
          amount: 2,
          unitPrice: Decimal(20)
        )
      ]
    )

    api.ordersToReturn = [order]
    api.orderToReturn = order

    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )

    let orders = try await sut.getOrders()
    #expect(orders.count == 1)
    #expect(orders.first?.currency?.code == "USD")
    #expect(orders.first?.items.first?.unitPrice == Decimal(20))

    let cached = try await sut.getOrder(by: 7)
    #expect(cached.customer?.fullname == "Ada Lovelace")
    #expect(cached.items.count == 1)
  }

  @Test
  func `getOrder returns the remote order without requiring a cache round trip`() async throws {
    let container = try makeContainer()
    let api = MockBooksAPIClient()
    let usd = Currency(id: 1, name: "US Dollar", symbol: "$", code: "USD")
    let order = Order(
      id: 9,
      customer: Customer(
        id: 2,
        fullname: "Ada Lovelace",
        email: "ada@example.com",
        address: "London",
        currency: usd
      ),
      currency: usd,
      description: "Direct fetch",
      totalPrice: Decimal(18),
      createdAt: Date(timeIntervalSince1970: 1_700_000_000),
      status: "paid",
      items: [
        OrderItem(
          id: 21,
          bookId: 1,
          book: sampleBook(id: 1, title: "Swift", price: 18),
          amount: 1,
          unitPrice: Decimal(18)
        )
      ]
    )

    api.orderToReturn = order

    let sut = BooksApplicationService(
      apiClient: api,
      cache: CacheStore(modelContainer: container)
    )

    let loaded = try await sut.getOrder(by: 9)
    #expect(loaded.id == 9)
    #expect(loaded.items.count == 1)
    #expect(loaded.formattedTotal.contains("18") || loaded.currency?.code == "USD")
  }
}

func makeContainer() throws -> ModelContainer {
  let configuration = ModelConfiguration(
    schema: Persistence.schema,
    isStoredInMemoryOnly: true
  )

  return try ModelContainer(
    for: Persistence.schema,
    configurations: configuration
  )
}

func sampleBook(
  id: Int,
  title: String,
  price: Decimal,
  authorName: String = "Apple"
) -> Book {
  let usd = Currency(id: 1, name: "US Dollar", symbol: "$", code: "USD")
  return Book(
    id: id,
    title: title,
    amount: 3,
    publishedYear: 2024,
    pagesCount: 200,
    typeOfBinding: "paperback",
    description: "A sample book",
    authors: [Author(id: 9, name: authorName)],
    genres: [Genre(id: 3, name: "Programming")],
    prices: [
      BookPrice(
        id: id * 10,
        bookId: id,
        price: price,
        currency: usd
      )
    ]
  )
}
