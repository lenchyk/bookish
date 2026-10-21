//
//  LoadingState.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.09.2026.
//

import Foundation

enum LoadingState: Equatable {
  case idle
  case loading
  case loaded
  case failed(String)

  var isLoading: Bool {
    if case .loading = self {
      return true
    }
    return false
  }

  var errorMessage: String? {
    if case .failed(let message) = self {
      return message
    }
    return nil
  }
}
