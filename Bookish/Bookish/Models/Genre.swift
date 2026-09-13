//
//  Genre.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

struct Genre: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let name: String

  init(id: Int, name: String) {
    self.id = id
    self.name = name
  }

  init(cache: GenreCache) {
    id = cache.id
    name = cache.name
  }
}
