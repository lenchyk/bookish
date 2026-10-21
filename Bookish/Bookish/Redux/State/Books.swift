//
//  Books.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct Books: Equatable {
  var byId: [Book.ID: Book] = [:]
  var authors: [Book.ID: [Author.ID]] = [:]
  var genres: [Book.ID: [Genre.ID]] = [:]
}
