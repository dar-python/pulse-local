<?php

namespace Tests\Feature;

use Tests\TestCase;

class FoodPulseLocalApiTest extends TestCase
{
    public function test_restaurants_endpoint_returns_local_restaurant_data(): void
    {
        $response = $this->getJson('/api/restaurants');

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'local-test-data',
                'data' => [
                    [
                        'id' => 1,
                        'name' => 'Tambayan Grill',
                        'cuisine' => 'Filipino - Grills',
                        'rating' => 4.8,
                        'delivery_time' => '15-25 min',
                        'minimum_order' => 99,
                        'risk_score' => 28,
                    ],
                ],
            ]);
    }

    public function test_restaurant_menu_endpoint_returns_menu_items_for_restaurant(): void
    {
        $response = $this->getJson('/api/restaurants/1/menu');

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'local-test-data',
                'data' => [
                    'restaurant' => [
                        'id' => 1,
                        'name' => 'Tambayan Grill',
                    ],
                    'items' => [
                        [
                            'id' => 1,
                            'name' => 'Pork Sinigang',
                            'price' => 185,
                            'category' => 'Bestsellers',
                        ],
                        [
                            'id' => 2,
                            'name' => 'Chicken Inasal',
                            'price' => 155,
                            'category' => 'Bestsellers',
                        ],
                    ],
                ],
            ]);
    }

    public function test_restaurant_menu_endpoint_returns_not_found_for_unknown_restaurant(): void
    {
        $response = $this->getJson('/api/restaurants/999/menu');

        $response->assertNotFound()
            ->assertJson([
                'success' => false,
                'message' => 'Restaurant not found.',
            ]);
    }

    public function test_cart_checkout_endpoint_returns_local_order_summary(): void
    {
        $response = $this->postJson('/api/cart/checkout', $this->checkoutPayload());

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'local-test-data',
                'data' => [
                    'order_number' => 'FP-2024-9873',
                    'status' => 'ready_for_confirmation',
                    'restaurant' => [
                        'id' => 1,
                        'name' => 'Tambayan Grill',
                    ],
                    'payment_method' => 'cod',
                    'subtotal' => 495,
                    'delivery_fee' => 49,
                    'service_charge' => 10,
                    'total' => 554,
                    'items' => [
                        [
                            'menu_item_id' => 1,
                            'name' => 'Pork Sinigang',
                            'quantity' => 1,
                            'line_total' => 185,
                        ],
                        [
                            'menu_item_id' => 2,
                            'name' => 'Chicken Inasal',
                            'quantity' => 2,
                            'line_total' => 310,
                        ],
                    ],
                    'risk' => [
                        'risk_score' => 68,
                        'risk_level' => 'Medium',
                    ],
                ],
            ]);
    }

    public function test_cart_checkout_endpoint_validates_cart_payload(): void
    {
        $response = $this->postJson('/api/cart/checkout', [
            'restaurant_id' => 1,
            'items' => [
                ['menu_item_id' => 999, 'quantity' => 1],
                ['menu_item_id' => 1, 'quantity' => 0],
            ],
            'payment_method' => 'wallet',
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors([
                'items.0.menu_item_id',
                'items.1.quantity',
                'payment_method',
                'delivery_address',
            ])
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace');

        $this->assertSame(['success', 'message', 'errors'], array_keys($response->json()));
    }

    public function test_cart_checkout_endpoint_rejects_unknown_restaurant(): void
    {
        $response = $this->postJson('/api/cart/checkout', [
            ...$this->checkoutPayload(),
            'restaurant_id' => 999,
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors(['restaurant_id']);

        $this->assertSame(
            'The selected restaurant is unavailable.',
            $response->json('errors')['restaurant_id'][0]
        );
    }

    public function test_cart_checkout_endpoint_rejects_unknown_menu_item(): void
    {
        $response = $this->postJson('/api/cart/checkout', [
            ...$this->checkoutPayload(),
            'items' => [
                ['menu_item_id' => 999, 'quantity' => 1],
            ],
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors(['items.0.menu_item_id']);

        $this->assertSame(
            'The selected menu item is unavailable.',
            $response->json('errors')['items.0.menu_item_id'][0]
        );
    }

    public function test_cart_checkout_endpoint_rejects_items_for_a_different_restaurant(): void
    {
        $response = $this->postJson('/api/cart/checkout', [
            ...$this->checkoutPayload(),
            'restaurant_id' => 2,
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors(['items.0.menu_item_id']);

        $this->assertSame(
            'The selected menu item is not available from this restaurant.',
            $response->json('errors')['items.0.menu_item_id'][0]
        );
    }

    public function test_cart_checkout_endpoint_rejects_empty_delivery_address(): void
    {
        $response = $this->postJson('/api/cart/checkout', [
            ...$this->checkoutPayload(),
            'delivery_address' => [
                'label' => '   ',
            ],
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors(['delivery_address.label']);

        $this->assertSame(
            'Enter a delivery address before checkout.',
            $response->json('errors')['delivery_address.label'][0]
        );
    }

    public function test_cart_checkout_endpoint_rejects_invalid_payment_method(): void
    {
        $response = $this->postJson('/api/cart/checkout', [
            ...$this->checkoutPayload(),
            'payment_method' => 'wallet',
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors(['payment_method'])
            ->assertJsonPath(
                'errors.payment_method.0',
                'Choose a supported payment method.'
            );
    }

    public function test_order_confirmation_endpoint_returns_confirmed_local_order(): void
    {
        $response = $this->getJson('/api/orders/FP-2024-9873/confirmation');

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'local-test-data',
                'data' => [
                    'order_number' => 'FP-2024-9873',
                    'status' => 'confirmed',
                    'estimated_arrival' => '30-45 min',
                    'total' => 554,
                    'risk' => [
                        'risk_score' => 68,
                        'risk_level' => 'Medium',
                    ],
                ],
            ]);
    }

    public function test_order_confirmation_endpoint_returns_not_found_for_unknown_order(): void
    {
        $response = $this->getJson('/api/orders/FP-0000/confirmation');

        $response->assertNotFound()
            ->assertJson([
                'success' => false,
                'message' => 'Order confirmation not found.',
            ]);
    }

    private function checkoutPayload(): array
    {
        return [
            'restaurant_id' => 1,
            'items' => [
                ['menu_item_id' => 1, 'quantity' => 1],
                ['menu_item_id' => 2, 'quantity' => 2],
            ],
            'payment_method' => 'cod',
            'delivery_address' => [
                'label' => 'Marasbaras, Tacloban City',
                'notes' => 'Zone 7, Leyte, Philippines',
            ],
        ];
    }
}
