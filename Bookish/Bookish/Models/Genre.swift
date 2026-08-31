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

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
  }

  init(cache: GenreCache) {
    self.init(id: cache.id, name: cache.name)
  }
}
