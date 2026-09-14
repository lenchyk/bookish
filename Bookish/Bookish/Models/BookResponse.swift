//
//  BookResponse.swift
//  Bookish
//
//  Created by Soroka, Olena on 18.06.2026.
//

struct BooksResponse: Decodable {
  let data: [Book]
  let page: Int
  let limit: Int
  let total: Int
  let hasMore: Bool
}

struct OrdersResponse: Decodable {
  let data: [Order]
  let page: Int
  let limit: Int
  let total: Int
  let hasMore: Bool
}
