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
  var books: [Book] = []
  var loadingState: LoadingState = .idle

  private var nextPage: Int?
  private let searchDebouncer = SearchDebouncer()

  init(service: BooksApplicationService) {
    self.service = service
    searchDebouncer.handler = { [weak self] text in
      await self?.search(with: text)
    }
  }

  func loadBooks() async {
    await fetchPage(1, reset: true)
  }

  func replaceBook(_ book: Book) {
    guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
    books[index] = book
  }

  func loadMoreIfNeeded(currentIndex: Int) {
    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    guard nextPage != nil else { return }
    let threshold = max(books.count - 3, 0)
    guard currentIndex >= threshold else { return }
    Task { await loadNextPage() }
  }

  func loadNextPage() async {
    guard loadingState != .loading else { return }
    guard let page = nextPage else { return }
    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    await fetchPage(page, reset: false)
  }

  func search(with text: String) async {
    let query = text.trimmingCharacters(in: .whitespacesAndNewlines)

    if query.isEmpty {
      await loadBooks()
      return
    }

    nextPage = nil
    loadingState = .loading

    do {
      let results = try await service.search(query: query)
      guard !Task.isCancelled else { return }
      guard searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
      books = results
      loadingState = .loaded
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      loadingState = .failed(error.localizedDescription)
    }
  }

  private func fetchPage(_ page: Int, reset: Bool) async {
    loadingState = .loading

    do {
      let response = try await service.getBooks(page: page)
      if reset {
        books = response.data
      } else {
        let existingIds = Set(books.map(\.id))
        books.append(contentsOf: response.data.filter { !existingIds.contains($0.id) })
      }
      nextPage = response.hasMore ? page + 1 : nil
      loadingState = .loaded
    } catch is CancellationError {
      loadingState = books.isEmpty ? .idle : .loaded
    } catch {
      loadingState = books.isEmpty
        ? .failed(error.localizedDescription)
        : .loaded
    }
  }

  func deleteBook(id: Int) async {
    do {
      try await service.deleteBook(id: id)
      books.removeAll { $0.id == id }
      loadingState = .loaded
    } catch {
      loadingState = .failed(error.localizedDescription)
    }
  }

  func removeBook(id: Int) {
    books.removeAll { $0.id == id }
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
