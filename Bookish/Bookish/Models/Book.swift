//
//  Book.swift
//  Bookish
//
//  Created by Soroka, Olena on 23.05.2026.
//

import Foundation

struct Book: Codable, Identifiable, Equatable {
  let id: Int
  let title: String
  let amount: Int
  let publishedYear: Int
  let pagesCount: Int
  let typeOfBinding: BindingType
  let description: String
  let authors: [Author]
  let genres: [Genre]
  let prices: [BookPrice]

  init(
    id: Int,
    title: String,
    amount: Int,
    publishedYear: Int,
    pagesCount: Int,
    typeOfBinding: BindingType,
    description: String,
    authors: [Author] = [],
    genres: [Genre] = [],
    prices: [BookPrice] = []
  ) {
    self.id = id
    self.title = title
    self.amount = amount
    self.publishedYear = publishedYear
    self.pagesCount = pagesCount
    self.typeOfBinding = typeOfBinding
    self.description = description
    self.authors = authors
    self.genres = genres
    self.prices = prices
  }

  init(cache: BookCache) {
    id = cache.id
    title = cache.title
    amount = cache.amount
    publishedYear = cache.publishedYear
    pagesCount = cache.pagesCount
    typeOfBinding = cache.typeOfBinding
    description = cache.bookDescription
    authors = cache.authors.map(Author.init(cache:))
    genres = cache.genres.map(Genre.init(cache:))
    prices = cache.prices.map(BookPrice.init(cache:))
  }

  var authorsDisplay: String {
    let names = authors.map(\.name).filter { !$0.isEmpty }
    return names.isEmpty ? "Unknown author" : names.joined(separator: ", ")
  }

  var genresDisplay: String {
    genres.map(\.name).filter { !$0.isEmpty }.joined(separator: ", ")
  }

  var primaryPrice: BookPrice? {
    prices.first
  }

  var formattedPrice: String {
    guard let primaryPrice else {
      return "Price unavailable"
    }
    return primaryPrice.formatted
  }
}

struct BookUpdate: Encodable {
  let title: String
  let amount: Int
  let publishedYear: Int
  let pagesCount: Int
  let typeOfBinding: BindingType
  let description: String
}
