//
//  OrdersListView.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import SwiftUI

struct OrdersListView: View {
  @Bindable var viewModel: OrdersListViewModel

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.orders.isEmpty && viewModel.isLoading {
          ProgressView("Loading orders…")
        } else if viewModel.orders.isEmpty, let error = viewModel.errorMessage {
          ContentUnavailableView {
            Label("Couldn’t load orders", systemImage: "wifi.slash")
          } description: {
            Text(error)
          } actions: {
            Button("Retry") {
              Task { await viewModel.loadOrders() }
            }
          }
        } else if viewModel.orders.isEmpty {
          ContentUnavailableView(
            "No orders",
            systemImage: "shippingbox",
            description: Text("Pull to refresh.")
          )
        } else {
          List(viewModel.orders) { order in
            NavigationLink {
              OrderDetailsView(order: order, service: viewModel.service)
            } label: {
              VStack(alignment: .leading, spacing: 6) {
                HStack {
                  Text("Order #\(order.id)")
                    .font(.headline)
                  Spacer()
                  Text(order.formattedTotal)
                    .fontWeight(.bold)
                }

                Text(order.customer?.displayName ?? "Unknown customer")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)

                HStack {
                  if let status = order.status, !status.isEmpty {
                    Text(status)
                      .font(.caption)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 4)
                      .background(Color.blue.opacity(0.15))
                      .foregroundStyle(.blue)
                      .clipShape(Capsule())
                  }

                  if let createdAt = order.createdAt {
                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
      .navigationTitle("Orders")
      .task {
        await viewModel.loadInitialIfNeeded()
      }
      .refreshable {
        await viewModel.loadOrders()
      }
    }
  }
}
