//
//  OrderDetailsView.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import SwiftUI

struct OrderDetailsView: View {
  @Bindable var viewModel: OrderDetailsViewModel

  var body: some View {
    Group {
      if let order = viewModel.order {
        orderContent(order)
      } else if viewModel.loadingState.isLoading {
        ProgressView("Loading order…")
      } else {
        ContentUnavailableView(
          "Order unavailable",
          systemImage: "exclamationmark.triangle",
          description: Text(viewModel.loadingState.errorMessage ?? "The order could not be loaded.")
        )
      }
    }
    .navigationTitle("Order #\(viewModel.orderId)")
    .task(id: viewModel.orderId) {
      await viewModel.loadOrder()
    }
  }

  @ViewBuilder
  private func orderContent(_ order: Order) -> some View {
    List {
      if let error = viewModel.loadingState.errorMessage {
        Section {
          Text(error)
            .foregroundStyle(.red)
        }
      }

      Section("Order") {
        LabeledContent("Status", value: order.status.displayName)
        LabeledContent(
          "Created",
          value: order.createdAt.formatted(date: .abbreviated, time: .shortened)
        )
        LabeledContent("Total", value: order.formattedTotal)
        LabeledContent(
          "Currency",
          value: [order.currency.code, order.currency.symbol, order.currency.name]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        )
        if !order.description.isEmpty {
          Text(order.description)
        }
      }

      Section("Customer") {
        Text(order.customer.displayName)
        if let email = order.customer.email, !email.isEmpty {
          Text(email)
            .foregroundStyle(.secondary)
        }
        if let address = order.customer.address, !address.isEmpty {
          Text(address)
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
              Text(item.book.title)
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
