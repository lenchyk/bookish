//
//  BookListViewModel.swift
//  Bookish
//
//  Created by Soroka, Olena on 24.05.2026.
//

import Foundation
import Observation
import Combine

@Observable
@MainActor
final class BooksListViewModel {
  let service: BooksApplicationService

  var searchText = "" {
    didSet {
      searchDebouncer.send(searchText)
    }
  }
  var errorMessage: String?
  var books: [Book] = []
  var isLoading = false
  private(set) var hasCompletedInitialLoad = false

  private var currentPage = 1
  private var hasMore = true
  private var isPaging = false
  private let searchDebouncer = SearchDebouncer()

  init(service: BooksApplicationService) {
    self.service = service
    searchDebouncer.handler = { [weak self] text in
      await self?.search(with: text)
    }
  }

  func loadInitialIfNeeded() async {
    guard !hasCompletedInitialLoad else { return }
    await loadBooks()
  }

  func loadBooks() async {
    currentPage = 1
    hasMore = true
    books.removeAll()
    await loadNextPage()
    hasCompletedInitialLoad = true
  }

  func loadMoreIfNeeded(currentIndex: Int) {
    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    let threshold = max(books.count - 3, 0)
    guard currentIndex >= threshold else { return }
    Task { await loadNextPage() }
  }

  func loadNextPage() async {
    guard !isPaging else { return }
    guard hasMore else { return }
    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    isPaging = true
    isLoading = books.isEmpty
    defer {
      isPaging = false
      isLoading = false
    }

    do {
      let response = try await service.getBooks(page: currentPage)
      let existingIds = Set(books.map(\.id))
      let newBooks = response.data.filter { !existingIds.contains($0.id) }
      books.append(contentsOf: newBooks)
      currentPage += 1
      hasMore = response.hasMore
      errorMessage = nil
    } catch is CancellationError {
      return
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func search(with text: String) async {
    let query = text.trimmingCharacters(in: .whitespacesAndNewlines)

    if query.isEmpty {
      await loadBooks()
      return
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let results = try await service.search(query: query)
      guard !Task.isCancelled else { return }
      guard searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
      errorMessage = nil
      books = results
      hasMore = false
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      errorMessage = error.localizedDescription
    }
  }

  func deleteBook(id: Int) async {
    do {
      try await service.deleteBook(id: id)
      removeBook(id: id)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func removeBook(id: Int) {
    books.removeAll { $0.id == id }
  }

  func replaceBook(_ book: Book) {
    if let index = books.firstIndex(where: { $0.id == book.id }) {
      books[index] = book
    }
  }
}

private final class SearchDebouncer {
  var handler: ((String) async -> Void)?

  private let subject = PassthroughSubject<String, Never>()
  private var cancellable: AnyCancellable?
  private var task: Task<Void, Never>?

  init() {
    cancellable = subject
      .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] text in
        guard let self else { return }
        self.task?.cancel()
        self.task = Task {
          await self.handler?(text)
        }
      }
  }

  func send(_ text: String) {
    subject.send(text)
  }
}
