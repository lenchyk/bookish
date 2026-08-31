//
//  OrderDetailsView.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import SwiftUI

struct OrderDetailsView: View {
  let orderId: Int
  @State private var viewModel: OrderDetailsViewModel

  init(order: Order, service: BooksApplicationService) {
    self.orderId = order.id
    _viewModel = State(
      initialValue: OrderDetailsViewModel(service: service, order: order)
    )
  }

  init(orderId: Int, service: BooksApplicationService) {
    self.orderId = orderId
    _viewModel = State(
      initialValue: OrderDetailsViewModel(service: service)
    )
  }

  var body: some View {
    Group {
      if let order = viewModel.order {
        orderContent(order)
      } else if viewModel.isLoading {
        ProgressView("Loading order…")
      } else {
        ContentUnavailableView(
          "Order unavailable",
          systemImage: "exclamationmark.triangle",
          description: Text(viewModel.errorMessage ?? "The order could not be loaded.")
        )
      }
    }
    .navigationTitle("Order #\(orderId)")
    .task(id: orderId) {
      await viewModel.loadOrder(id: orderId)
    }
  }

  @ViewBuilder
  private func orderContent(_ order: Order) -> some View {
    List {
      if let error = viewModel.errorMessage {
        Section {
          Text(error)
            .foregroundStyle(.red)
        }
      }

      Section("Order") {
        LabeledContent("Status", value: order.status ?? "Unknown")
        if let createdAt = order.createdAt {
          LabeledContent(
            "Created",
            value: createdAt.formatted(date: .abbreviated, time: .shortened)
          )
        }
        LabeledContent("Total", value: order.formattedTotal)
        if let currency = order.currency {
          LabeledContent(
            "Currency",
            value: [currency.code, currency.symbol, currency.name]
              .compactMap { $0 }
              .filter { !$0.isEmpty }
              .joined(separator: " · ")
          )
        }
        if let description = order.description, !description.isEmpty {
          Text(description)
        }
      }

      Section("Customer") {
        if let customer = order.customer {
          Text(customer.displayName)
          if let email = customer.email, !email.isEmpty {
            Text(email)
              .foregroundStyle(.secondary)
          }
          if let address = customer.address, !address.isEmpty {
            Text(address)
              .foregroundStyle(.secondary)
          }
        } else {
          Text("Customer unavailable")
            .foregroundStyle(.secondary)
        }
      }

      Section("Items") {
        if order.items.isEmpty {
          Text("No items")
            .foregroundStyle(.secondary)
        } else {
          ForEach(order.items) { item in
            VStack(alignment: .leading, spacing: 6) {
              Text(item.book?.title ?? "Unknown book")
                .font(.headline)
              Text("Qty: \(item.amount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
              HStack {
                Text(item.formattedUnitPrice(currency: order.currency))
                Spacer()
                Text(item.formattedLineTotal(currency: order.currency))
                  .fontWeight(.semibold)
              }
              .font(.callout)
            }
            .padding(.vertical, 4)
          }
        }
      }
    }
  }
}
