//
//  BookDetailsViewModel.swift
//  Bookish
//
//  Created by Soroka, Olena on 25.05.2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class BookDetailsViewModel {
  private let service: BooksApplicationService

  var book: Book?
  var isLoading = false
  var errorMessage: String?
  var didDelete = false

  init(service: BooksApplicationService) {
    self.service = service
  }

  func loadBook(id: Int) async {
    isLoading = true
    defer { isLoading = false }

    do {
      book = try await service.getBook(by: id)
      errorMessage = nil
    } catch is CancellationError {
      return
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func updateBook(id: Int, update: BookUpdate) async {
    do {
      try await service.updateBook(id: id, update: update)
      book = try await service.getBook(by: id)
      errorMessage = nil
    } catch is CancellationError {
      return
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func deleteBook(id: Int) async {
    do {
      try await service.deleteBook(id: id)
      didDelete = true
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
