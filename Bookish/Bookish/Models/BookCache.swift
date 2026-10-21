//
//  BookCache.swift
//  Bookish
//
//  Created by Soroka, Olena on 23.05.2026.
//

import Foundation
import SwiftData

@Model
final class BookCache {
  @Attribute(.unique) var id: Int
  var title: String
  var amount: Int
  var publishedYear: Int
  var pagesCount: Int
  var typeOfBinding: BindingType
  var bookDescription: String

  @Relationship(deleteRule: .nullify, inverse: \AuthorCache.books)
  var authors: [AuthorCache]

  @Relationship(deleteRule: .nullify, inverse: \GenreCache.books)
  var genres: [GenreCache]

  @Relationship(deleteRule: .cascade, inverse: \BookPriceCache.book)
  var prices: [BookPriceCache]

  init(
    id: Int,
    title: String,
    amount: Int,
    publishedYear: Int,
    pagesCount: Int,
    typeOfBinding: BindingType,
    bookDescription: String,
    authors: [AuthorCache] = [],
    genres: [GenreCache] = [],
    prices: [BookPriceCache] = []
  ) {
    self.id = id
    self.title = title
    self.amount = amount
    self.publishedYear = publishedYear
    self.pagesCount = pagesCount
    self.typeOfBinding = typeOfBinding
    self.bookDescription = bookDescription
    self.authors = authors
    self.genres = genres
    self.prices = prices
  }

  convenience init(book: Book) {
    self.init(
      id: book.id,
      title: book.title,
      amount: book.amount,
      publishedYear: book.publishedYear,
      pagesCount: book.pagesCount,
      typeOfBinding: book.typeOfBinding,
      bookDescription: book.description
    )
  }

  func update(from book: Book) {
    title = book.title
    amount = book.amount
    publishedYear = book.publishedYear
    pagesCount = book.pagesCount
    typeOfBinding = book.typeOfBinding
    bookDescription = book.description
  }
}

@Model
final class AuthorCache {
  @Attribute(.unique) var id: Int
  var name: String
  var books: [BookCache]

  init(id: Int, name: String, books: [BookCache] = []) {
    self.id = id
    self.name = name
    self.books = books
  }

  func update(from author: Author) {
    name = author.name
  }
}

@Model
final class GenreCache {
  @Attribute(.unique) var id: Int
  var name: String
  var books: [BookCache]

  init(id: Int, name: String, books: [BookCache] = []) {
    self.id = id
    self.name = name
    self.books = books
  }

  func update(from genre: Genre) {
    name = genre.name
  }
}

@Model
final class CurrencyCache {
  @Attribute(.unique) var id: Int
  var name: String
  var symbol: String
  var code: String

  init(
    id: Int,
    name: String,
    symbol: String,
    code: String
  ) {
    self.id = id
    self.name = name
    self.symbol = symbol
    self.code = code
  }

  func update(from currency: Currency) {
    name = currency.name
    symbol = currency.symbol
    code = currency.code
  }
}

@Model
final class BookPriceCache {
  @Attribute(.unique) var id: Int
  var bookId: Int
  var price: Decimal
  var createdAt: Date?
  var currency: CurrencyCache
  var book: BookCache?

  init(
    id: Int,
    bookId: Int,
    price: Decimal,
    createdAt: Date? = nil,
    currency: CurrencyCache,
    book: BookCache? = nil
  ) {
    self.id = id
    self.bookId = bookId
    self.price = price
    self.createdAt = createdAt
    self.currency = currency
    self.book = book
  }

  func update(from price: BookPrice, currency: CurrencyCache) {
    bookId = price.bookId
    self.price = price.price
    createdAt = price.createdAt
    self.currency = currency
  }
}
