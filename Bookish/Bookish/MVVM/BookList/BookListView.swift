//
//  BookListView.swift
//  Bookish
//
//  Created by Soroka, Olena on 25.05.2026.
//

import SwiftUI

struct BooksListView: View {
  @Bindable var viewModel: BooksListViewModel

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.books.isEmpty && viewModel.loadingState.isLoading {
          ProgressView("Loading books…")
        } else if viewModel.books.isEmpty, let error = viewModel.loadingState.errorMessage {
          ContentUnavailableView {
            Label("Couldn’t load books", systemImage: "wifi.slash")
          } description: {
            Text(error)
          } actions: {
            Button("Retry") {
              Task { await viewModel.loadBooks() }
            }
          }
        } else if viewModel.books.isEmpty {
          ContentUnavailableView(
            "No books",
            systemImage: "book",
            description: Text("Pull to refresh or try a different search.")
          )
        } else {
          List {
            ForEach(Array(viewModel.books.enumerated()), id: \.element.id) { index, book in
              NavigationLink {
                BookDetailsView(
                  viewModel: BookDetailsViewModel(
                    bookId: book.id,
                    service: viewModel.service,
                    onBookChanged: { viewModel.replaceBook($0) },
                    onBookDeleted: { viewModel.removeBook(id: $0) }
                  )
                )
              } label: {
                BookRowView(book: book)
              }
              .onAppear {
                viewModel.loadMoreIfNeeded(currentIndex: index)
              }
            }
          }
        }
      }
      .refreshable {
        if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          await viewModel.loadBooks()
        } else {
          await viewModel.search(with: viewModel.searchText)
        }
      }
      .navigationTitle("Books")
      .task {
        guard viewModel.books.isEmpty else { return }
        await viewModel.loadBooks()
      }
      .searchable(text: $viewModel.searchText, prompt: "Search for a book...")
    }
  }
}
