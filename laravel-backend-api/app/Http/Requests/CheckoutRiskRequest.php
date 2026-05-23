<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ReturnsApiValidationErrors;
use App\Services\FoodPulseLocalData;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class CheckoutRiskRequest extends FormRequest
{
    use ReturnsApiValidationErrors;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $items = $this->input('items', []);

        if (is_array($items)) {
            $items = array_map(function (mixed $item): mixed {
                if (! is_array($item)) {
                    return $item;
                }

                if (! isset($item['id']) && isset($item['menu_item_id'])) {
                    $item['id'] = $item['menu_item_id'];
                }

                if (! isset($item['unit_price']) && isset($item['price'])) {
                    $item['unit_price'] = $item['price'];
                }

                return $item;
            }, $items);
        }

        $this->merge([
            'restaurant_slug' => is_string($this->restaurant_slug)
                ? Str::slug($this->restaurant_slug)
                : $this->restaurant_slug,
            'payment_method' => is_string($this->payment_method)
                ? strtolower($this->payment_method)
                : $this->payment_method,
            'items' => $items,
        ]);
    }

    public function rules(): array
    {
        $foodPulseData = app(FoodPulseLocalData::class);

        return [
            'restaurant_id' => [
                'required_without:restaurant_slug',
                'nullable',
                'integer',
                Rule::in($foodPulseData->restaurantIds()),
            ],
            'restaurant_slug' => [
                'required_without:restaurant_id',
                'nullable',
                'string',
                'max:80',
            ],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['required', 'integer', 'min:1'],
            'items.*.name' => ['required', 'string', 'max:120'],
            'items.*.category' => ['required', 'string', 'max:80'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:10'],
            'items.*.unit_price' => ['required', 'numeric', 'min:0'],
            'delivery_address' => ['required', 'array'],
            'delivery_address.label' => ['required', 'string', 'max:160'],
            'delivery_address.notes' => ['nullable', 'string', 'max:240'],
            'payment_method' => ['required', 'string', 'in:cod,cash,gcash,card'],
            'subtotal' => ['nullable', 'numeric', 'min:0'],
            'total_quantity' => ['nullable', 'integer', 'min:1'],
            'delivery_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'delivery_longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'delivery_distance_km' => ['nullable', 'numeric', 'min:0', 'max:50'],
            'merchant_prep_time' => ['nullable', 'integer', 'min:0', 'max:120'],
            'rider_to_order_ratio' => ['nullable', 'numeric', 'between:0,2'],
            'traffic_corridor_intensity' => ['nullable', 'string', 'in:low,medium,high'],
            'weather_category' => ['nullable', 'string', 'in:clear,rainy,stormy'],
            'address_complexity' => ['nullable', 'string', 'in:low,medium,high'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $restaurantSlug = $this->input('restaurant_slug');

            if ($restaurantSlug === null || $restaurantSlug === '') {
                return;
            }

            $knownSlugs = array_map(
                fn (array $restaurant): string => Str::slug((string) $restaurant['name']),
                app(FoodPulseLocalData::class)->restaurants()
            );

            if (! in_array($restaurantSlug, $knownSlugs, true)) {
                $validator->errors()->add(
                    'restaurant_slug',
                    'The selected restaurant is unavailable.'
                );
            }
        });
    }

    public function messages(): array
    {
        return [
            'restaurant_id.required_without' => 'Choose a restaurant before checkout.',
            'restaurant_id.in' => 'The selected restaurant is unavailable.',
            'restaurant_slug.required_without' => 'Choose a restaurant before checkout.',
            'items.required' => 'Add at least one cart item before checkout.',
            'items.array' => 'Add at least one cart item before checkout.',
            'items.min' => 'Add at least one cart item before checkout.',
            'items.*.id.required' => 'Choose a cart item before checkout.',
            'items.*.name.required' => 'Cart item name is required.',
            'items.*.category.required' => 'Cart item category is required.',
            'items.*.quantity.required' => 'Quantity must be at least 1.',
            'items.*.quantity.min' => 'Quantity must be at least 1.',
            'items.*.quantity.max' => 'Quantity cannot exceed 10.',
            'items.*.unit_price.required' => 'Cart item unit price is required.',
            'items.*.unit_price.min' => 'Cart item unit price cannot be negative.',
            'delivery_address.required' => 'Enter a delivery address before checkout.',
            'delivery_address.array' => 'Enter a delivery address before checkout.',
            'delivery_address.label.required' => 'Enter a delivery address before checkout.',
            'payment_method.required' => 'Choose a payment method.',
            'payment_method.in' => 'Choose a supported payment method.',
        ];
    }
}
