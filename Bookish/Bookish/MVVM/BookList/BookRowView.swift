//
//  BookRowView.swift
//  Bookish
//
//  Created by Soroka, Olena on 25.05.2026.
//

import SwiftUI

struct BookRowView: View {
  let book: Book

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(book.title)
        .font(.headline)
        .bold()

      Text(book.authorsDisplay)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(alignment: .top) {
        if book.genres.isEmpty {
          GenreChip(title: "Uncategorized")
        } else {
          FlexibleGenreRow(names: book.genres.map(\.name))
        }

        Spacer(minLength: 8)

        Text(book.formattedPrice)
          .fontWeight(.bold)
          .font(.callout)
      }
    }
    .padding(.vertical, 4)
  }
}

private struct FlexibleGenreRow: View {
  let names: [String]

  var body: some View {
    HStack(spacing: 6) {
      ForEach(names.prefix(2), id: \.self) { name in
        GenreChip(title: name)
      }

      if names.count > 2 {
        Text("+\(names.count - 2)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct GenreChip: View {
  let title: String

  var body: some View {
    Text(title)
      .font(.callout)
      .fontWeight(.semibold)
      .foregroundStyle(.blue)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Color.blue.opacity(0.15))
      .clipShape(Capsule())
  }
}
