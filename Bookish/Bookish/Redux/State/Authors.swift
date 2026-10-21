//
//  Authors.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct Authors: Equatable {
  var byId: [Author.ID: Author] = [:]
  var books: [Author.ID: [Book.ID]] = [:]
}
