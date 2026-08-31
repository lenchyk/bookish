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
  let amount: Int?
  let publishedYear: Int?
  let pagesCount: Int?
  let typeOfBinding: String?
  let description: String?
  let authors: [Author]
  let genres: [Genre]
  let prices: [BookPrice]

  init(
    id: Int,
    title: String,
    amount: Int? = nil,
    publishedYear: Int? = nil,
    pagesCount: Int? = nil,
    typeOfBinding: String? = nil,
    description: String? = nil,
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

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    amount = try container.decodeIfPresent(Int.self, forKey: .amount)
    publishedYear = try container.decodeIfPresent(Int.self, forKey: .publishedYear)
    pagesCount = try container.decodeIfPresent(Int.self, forKey: .pagesCount)
    typeOfBinding = try container.decodeIfPresent(String.self, forKey: .typeOfBinding)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    authors = try container.decodeIfPresent([Author].self, forKey: .authors) ?? []
    genres = try container.decodeIfPresent([Genre].self, forKey: .genres) ?? []
    prices = try container.decodeIfPresent([BookPrice].self, forKey: .prices) ?? []
  }

  init(cache: BookCache) {
    self.init(
      id: cache.id,
      title: cache.title,
      amount: cache.amount,
      publishedYear: cache.publishedYear,
      pagesCount: cache.pagesCount,
      typeOfBinding: cache.typeOfBinding,
      description: cache.bookDescription,
      authors: cache.authors.map(Author.init(cache:)),
      genres: cache.genres.map(Genre.init(cache:)),
      prices: cache.prices.map(BookPrice.init(cache:))
    )
  }

  var authorsDisplay: String {
    let names = authors.map(\.name).filter { !$0.isEmpty }
    return names.isEmpty ? "Unknown author" : names.joined(separator: ", ")
  }

  var genresDisplay: String {
    let names = genres.map(\.name).filter { !$0.isEmpty }
    return names.joined(separator: ", ")
  }

  var primaryPrice: BookPrice? {
    prices.first { $0.price != nil }
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
  let amount: Int?
  let publishedYear: Int?
  let pagesCount: Int?
  let typeOfBinding: String?
  let description: String?
}
