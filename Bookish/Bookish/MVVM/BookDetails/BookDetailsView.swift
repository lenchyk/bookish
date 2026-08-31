//
//  BookDetailsView.swift
//  Bookish
//
//  Created by Soroka, Olena on 25.05.2026.
//

import SwiftUI

struct BookDetailsView: View {
  let bookId: Int
  let onBookChanged: ((Book) -> Void)?
  let onBookDeleted: ((Int) -> Void)?

  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: BookDetailsViewModel
  @State private var showDeleteConfirm = false

  @State private var title = ""
  @State private var amount = ""
  @State private var publishedYear = ""
  @State private var pagesCount = ""
  @State private var typeOfBinding = ""
  @State private var descriptionText = ""

  init(
    bookId: Int,
    service: BooksApplicationService,
    onBookChanged: ((Book) -> Void)? = nil,
    onBookDeleted: ((Int) -> Void)? = nil
  ) {
    self.bookId = bookId
    self.onBookChanged = onBookChanged
    self.onBookDeleted = onBookDeleted
    _viewModel = State(initialValue: BookDetailsViewModel(service: service))
  }

  var body: some View {
    Form {
      if let error = viewModel.errorMessage {
        Section {
          Text(error)
            .foregroundStyle(.red)
        }
      }

      Section("Book") {
        TextField("Title", text: $title)
        TextField("Stock amount", text: $amount)
          .keyboardType(.numberPad)
        TextField("Published year", text: $publishedYear)
          .keyboardType(.numberPad)
        TextField("Page count", text: $pagesCount)
          .keyboardType(.numberPad)
        TextField("Binding type", text: $typeOfBinding)
        TextField("Description", text: $descriptionText, axis: .vertical)
          .lineLimit(3...8)
      }

      if let book = viewModel.book {
        Section("Authors") {
          if book.authors.isEmpty {
            Text("No authors listed")
              .foregroundStyle(.secondary)
          } else {
            ForEach(book.authors) { author in
              Text(author.name)
            }
          }
        }

        Section("Genres") {
          if book.genres.isEmpty {
            Text("No genres listed")
              .foregroundStyle(.secondary)
          } else {
            ForEach(book.genres) { genre in
              Text(genre.name)
            }
          }
        }

        Section("Prices") {
          if book.prices.isEmpty {
            Text("Price unavailable")
              .foregroundStyle(.secondary)
          } else {
            ForEach(book.prices) { price in
              HStack {
                Text(price.formatted)
                Spacer()
                if let code = price.currency?.code {
                  Text(code)
                    .foregroundStyle(.secondary)
                }
              }
            }
          }
        }
      }
    }
    .navigationTitle("Details")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Save") {
          Task {
            await viewModel.updateBook(
              id: bookId,
              update: BookUpdate(
                title: title,
                amount: Int(amount),
                publishedYear: Int(publishedYear),
                pagesCount: Int(pagesCount),
                typeOfBinding: typeOfBinding.isEmpty ? nil : typeOfBinding,
                description: descriptionText.isEmpty ? nil : descriptionText
              )
            )
            populateFields(from: viewModel.book)
            if let book = viewModel.book {
              onBookChanged?(book)
            }
          }
        }
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button("Delete", role: .destructive) {
          showDeleteConfirm = true
        }
      }
    }
    .alert("Delete this book?", isPresented: $showDeleteConfirm) {
      Button("Delete", role: .destructive) {
        Task {
          await viewModel.deleteBook(id: bookId)
          if viewModel.didDelete {
            onBookDeleted?(bookId)
            dismiss()
          }
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
    .task {
      await viewModel.loadBook(id: bookId)
      populateFields(from: viewModel.book)
    }
    .onChange(of: viewModel.didDelete) { _, didDelete in
      if didDelete {
        onBookDeleted?(bookId)
        dismiss()
      }
    }
  }

  private func populateFields(from book: Book?) {
    guard let book else { return }
    title = book.title
    amount = book.amount.map(String.init) ?? ""
    publishedYear = book.publishedYear.map(String.init) ?? ""
    pagesCount = book.pagesCount.map(String.init) ?? ""
    typeOfBinding = book.typeOfBinding ?? ""
    descriptionText = book.description ?? ""
  }
}
