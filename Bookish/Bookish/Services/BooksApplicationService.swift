//
//  BooksApplicationService.swift
//  Bookish
//
//  Created by Soroka, Olena on 25.05.2026.
//

import Foundation

final class BooksApplicationService {
  private let apiClient: any APIClientProtocol
  private let cache: CacheStore

  init(
    apiClient: any APIClientProtocol,
    cache: CacheStore
  ) {
    self.apiClient = apiClient
    self.cache = cache
  }

  // MARK: - Books

  func getBooks(page: Int) async throws -> BooksResponse {
    do {
      let response = try await apiClient.getBooks(page: page, limit: BookishPaging.pageSize)
      try await cache.upsertBooks(response.data)
      return response
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      let cached = try await cache.booksPage(page: page)
      if cached.items.isEmpty {
        throw error
      }
      return BooksResponse(
        data: cached.items,
        page: page,
        limit: BookishPaging.pageSize,
        total: cached.items.count,
        hasMore: cached.hasMore
      )
    }
  }

  func getBook(by id: Int) async throws -> Book {
    do {
      let remoteBook = try await apiClient.getBook(by: id)
      try await cache.upsertBooks([remoteBook])
      return remoteBook
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      if let cachedBook = try await cache.book(id: id) {
        return cachedBook
      }
      throw error
    }
  }

  func updateBook(id: Int, update: BookUpdate) async throws {
    try await apiClient.updateBook(id: id, update: update)

    if let cached = try await cache.book(id: id) {
      let updated = Book(
        id: id,
        title: update.title,
        amount: update.amount,
        publishedYear: update.publishedYear,
        pagesCount: update.pagesCount,
        typeOfBinding: update.typeOfBinding,
        description: update.description,
        authors: cached.authors,
        genres: cached.genres,
        prices: cached.prices
      )
      try await cache.upsertBooks([updated])
    }
  }

  func search(query: String) async throws -> [Book] {
    do {
      return try await apiClient.search(query: query)
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      let cached = try await cache.searchBooks(query: query)
      if cached.isEmpty {
        throw error
      }
      return cached
    }
  }

  func deleteBook(id: Int) async throws {
    try await apiClient.deleteBook(id: id)
    try await cache.deleteBook(id: id)
  }

  func getCachedBook(id: Int) async throws -> Book? {
    try await cache.book(id: id)
  }

  func getCachedBooks(page: Int = 1) async throws -> CachedPage<Book> {
    try await cache.booksPage(page: page)
  }

  // MARK: - Customers & Orders

  func getCustomers() async throws -> [Customer] {
    do {
      let customers = try await apiClient.getCustomers()
      try await cache.upsertCustomers(customers)
      return customers
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      let cached = try await cache.customers()
      if cached.isEmpty {
        throw error
      }
      return cached
    }
  }

  func getOrders(page: Int = 1) async throws -> [Order] {
    do {
      let response = try await apiClient.getOrders(page: page, limit: BookishPaging.pageSize)
      try await cache.upsertOrders(response.data)
      return response.data
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      let cached = try await cache.orders()
      if cached.isEmpty {
        throw error
      }
      return cached
    }
  }

  func getOrder(by id: Int) async throws -> Order {
    do {
      let order = try await apiClient.getOrder(by: id)
      try? await cache.upsertOrder(order)
      return order
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      if let cached = try await cache.order(id: id) {
        return cached
      }
      throw error
    }
  }
}
