//
//  BooksAPIClient.swift
//  Bookish
//
//  Created by Soroka, Olena on 24.05.2026.
//

import Foundation

protocol BooksAPIProtocol {
  func getBooks(page: Int, limit: Int) async throws -> BooksResponse
  func getBook(by id: Book.ID) async throws -> Book
  func updateBook(id: Book.ID, update: BookUpdate) async throws
  func search(query: String) async throws -> [Book]
  func deleteBook(id: Book.ID) async throws
}

protocol OrdersAPIProtocol {
  func getOrders(page: Int, limit: Int) async throws -> OrdersResponse
  func getOrder(by id: Order.ID) async throws -> Order
}

protocol CustomersAPIProtocol {
  func getCustomers() async throws -> [Customer]
}

typealias APIClientProtocol = BooksAPIProtocol & OrdersAPIProtocol & CustomersAPIProtocol

final class APIClient: APIClientProtocol {
  private let baseURL: URL
  private let session: URLSession

  init(
    baseURL: URL = APIConfiguration.baseURL,
    session: URLSession = .shared
  ) {
    self.baseURL = baseURL
    self.session = session
  }

  func getBooks(page: Int, limit: Int = BookishPaging.pageSize) async throws -> BooksResponse {
    try await get(
      path: "/books",
      queryItems: [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "limit", value: String(limit))
      ]
    )
  }

  func getBook(by id: Book.ID) async throws -> Book {
    try await get(path: "/books/\(id.id)")
  }

  func updateBook(id: Book.ID, update: BookUpdate) async throws {
    let url = try makeURL(path: "/books/\(id.id)")
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try APIJSON.encoder.encode(update)
    _ = try await send(request)
  }

  func search(query: String) async throws -> [Book] {
    try await get(
      path: "/books/search",
      queryItems: [
        URLQueryItem(name: "query", value: query)
      ]
    )
  }

  func deleteBook(id: Book.ID) async throws {
    let url = try makeURL(path: "/books/\(id.id)")
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    _ = try await send(request)
  }

  func getCustomers() async throws -> [Customer] {
    try await get(path: "/customers")
  }

  func getOrders(page: Int, limit: Int = BookishPaging.pageSize) async throws -> OrdersResponse {
    try await get(
      path: "/orders",
      queryItems: [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "limit", value: String(limit))
      ]
    )
  }

  func getOrder(by id: Order.ID) async throws -> Order {
    try await get(path: "/orders/\(id.id)")
  }

  private func get<T: Decodable>(
    path: String,
    queryItems: [URLQueryItem] = []
  ) async throws -> T {
    let url = try makeURL(path: path, queryItems: queryItems)
    let data = try await send(URLRequest(url: url))
    return try APIJSON.decoder.decode(T.self, from: data)
  }

  private func makeURL(
    path: String,
    queryItems: [URLQueryItem] = []
  ) throws -> URL {
    let relative = path.hasPrefix("/") ? String(path.dropFirst()) : path
    guard var components = URLComponents(
      url: baseURL.appending(path: relative),
      resolvingAgainstBaseURL: false
    ) else {
      throw APIError.badURL
    }
    if !queryItems.isEmpty {
      components.queryItems = queryItems
    }
    guard let url = components.url else {
      throw APIError.badURL
    }
    return url
  }

  private func send(_ request: URLRequest) async throws -> Data {
    let (data, response) = try await session.data(for: request)
    if let http = response as? HTTPURLResponse,
       !(200...299).contains(http.statusCode) {
      throw APIError.httpStatus(http.statusCode)
    }
    return data
  }
}
