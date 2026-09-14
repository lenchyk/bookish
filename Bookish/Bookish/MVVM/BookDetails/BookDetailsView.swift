//
//  BookDetailsView.swift
//  Bookish
//
//  Created by Soroka, Olena on 25.05.2026.
//

import SwiftUI

struct BookDetailsView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var viewModel: BookDetailsViewModel
  @State private var showDeleteConfirm = false

  var body: some View {
    Form {
      if let error = viewModel.loadingState.errorMessage {
        Section {
          Text(error)
            .foregroundStyle(.red)
        }
      }

      Section("Book") {
        TextField("Title", text: $viewModel.title)
        TextField("Stock amount", text: $viewModel.amount)
          .keyboardType(.numberPad)
        TextField("Published year", text: $viewModel.publishedYear)
          .keyboardType(.numberPad)
        TextField("Page count", text: $viewModel.pagesCount)
          .keyboardType(.numberPad)
        Picker("Binding type", selection: $viewModel.typeOfBinding) {
          ForEach(BindingType.allCases, id: \.self) { binding in
            Text(binding.displayName).tag(binding)
          }
        }
        TextField("Description", text: $viewModel.descriptionText, axis: .vertical)
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
                Text(price.currency.code)
                  .foregroundStyle(.secondary)
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
          Task { await viewModel.save() }
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
          await viewModel.deleteBook()
          if viewModel.didDelete {
            dismiss()
          }
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
    .task {
      await viewModel.loadBook()
    }
    .onChange(of: viewModel.didDelete) { _, didDelete in
      if didDelete {
        dismiss()
      }
    }
  }
}
