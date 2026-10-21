//
//  BookSearch.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

enum BookSearch: Equatable {
  case search(String)
  case loading
  case loaded([Book.ID])
  case error(Error)

  static func == (lhs: BookSearch, rhs: BookSearch) -> Bool {
    switch (lhs, rhs) {
    case let (.search(lhsQuery), .search(rhsQuery)):
      lhsQuery == rhsQuery
    case (.loading, .loading):
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
