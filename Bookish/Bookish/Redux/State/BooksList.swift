//
//  BooksList.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

enum BooksList: Equatable {
  case idle
  case loading
  case loaded([Book.ID])
  case error(Error)

  static func == (lhs: BooksList, rhs: BooksList) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle), (.loading, .loading):
      true
    case let (.loaded(lhsIDs), .loaded(rhsIDs)):
      lhsIDs == rhsIDs
    case let (.error(lhsError), .error(rhsError)):
      lhsError.localizedDescription == rhsError.localizedDescription
    default:
      false
    }
  }
}
