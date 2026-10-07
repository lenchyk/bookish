//
//  Genres.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct Genres: Equatable {
  var byId: [Genre.ID: Genre] = [:]
  var books: [Genre.ID: [Book.ID]] = [:]
}
