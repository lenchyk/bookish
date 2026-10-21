//
//  BookGenres.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct BookGenres: Equatable {
  var genreIdsByBookId: [Book.ID: [Genre.ID]] = [:]
  var bookIdsByGenreId: [Genre.ID: [Book.ID]] = [:]
}
