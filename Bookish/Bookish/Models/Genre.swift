//
//  Genre.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Genre: Codable, Identifiable, Equatable, Hashable {
  typealias ID = Identifier<Genre>

  let id: ID
  let name: String

  init(id: ID, name: String) {
    self.id = id
    self.name = name
  }

  init(cache: GenreCache) {
    id = ID(id: cache.id)
    name = cache.name
  }
}
