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
  let bookId: Int
  private let service: BooksApplicationService
  private let onBookChanged: ((Book) -> Void)?
  private let onBookDeleted: ((Int) -> Void)?

  var book: Book?
  var loadingState: LoadingState = .idle
  var didDelete = false

  var title = ""
  var amount = ""
  var publishedYear = ""
  var pagesCount = ""
  var typeOfBinding: BindingType = .paperback
  var descriptionText = ""

  init(
    bookId: Int,
    service: BooksApplicationService,
    onBookChanged: ((Book) -> Void)? = nil,
    onBookDeleted: ((Int) -> Void)? = nil
  ) {
    self.bookId = bookId
    self.service = service
    self.onBookChanged = onBookChanged
    self.onBookDeleted = onBookDeleted
  }

  func loadBook() async {
    loadingState = .loading

    do {
      let loaded = try await service.getBook(by: bookId)
      book = loaded
      populateFields(from: loaded)
      loadingState = .loaded
    } catch is CancellationError {
      return
    } catch {
      loadingState = .failed(error.localizedDescription)
    }
  }

  func save() async {
    guard
      let amountValue = Int(amount),
      let publishedYearValue = Int(publishedYear),
      let pagesCountValue = Int(pagesCount)
    else {
      loadingState = .failed("Please fill in valid book details.")
      return
    }

    let update = BookUpdate(
      title: title,
      amount: amountValue,
      publishedYear: publishedYearValue,
      pagesCount: pagesCountValue,
      typeOfBinding: typeOfBinding,
      description: descriptionText
    )

    do {
      try await service.updateBook(id: bookId, update: update)
      let loaded = try await service.getBook(by: bookId)
      book = loaded
      populateFields(from: loaded)
      loadingState = .loaded
      onBookChanged?(loaded)
    } catch is CancellationError {
      return
    } catch {
      loadingState = .failed(error.localizedDescription)
    }
  }

  func deleteBook() async {
    do {
      try await service.deleteBook(id: bookId)
      didDelete = true
      loadingState = .loaded
      onBookDeleted?(bookId)
    } catch {
      loadingState = .failed(error.localizedDescription)
    }
  }

  private func populateFields(from book: Book) {
    title = book.title
    amount = String(book.amount)
    publishedYear = String(book.publishedYear)
    pagesCount = String(book.pagesCount)
    typeOfBinding = book.typeOfBinding
    descriptionText = book.description
  }
}
