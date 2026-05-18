<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ReturnsApiValidationErrors;
use App\Services\FoodPulseLocalData;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class CartCheckoutRequest extends FormRequest
{
    use ReturnsApiValidationErrors;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'payment_method' => is_string($this->payment_method)
                ? strtolower($this->payment_method)
                : $this->payment_method,
        ]);
    }

    public function rules(): array
    {
        $foodPulseData = app(FoodPulseLocalData::class);

        return [
            'restaurant_id' => [
                'required',
                'integer',
                Rule::in($foodPulseData->restaurantIds()),
            ],
            'items' => ['required', 'array', 'min:1'],
            'items.*.menu_item_id' => [
                'required',
                'integer',
                Rule::in($foodPulseData->menuItemIds()),
            ],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:10'],
            'payment_method' => ['required', 'string', 'in:cod,cash,gcash,card'],
            'delivery_address' => ['required', 'array'],
            'delivery_address.label' => ['required', 'string', 'max:160'],
            'delivery_address.notes' => ['nullable', 'string', 'max:240'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $restaurantId = $this->integer('restaurant_id');
            $items = $this->input('items', []);

            if (
                $restaurantId === 0
                || ! is_array($items)
                || ! in_array($restaurantId, app(FoodPulseLocalData::class)->restaurantIds(), true)
            ) {
                return;
            }

            $restaurantMenuItemIds = array_column(
                app(FoodPulseLocalData::class)->menuItems($restaurantId),
                'id'
            );

            foreach ($items as $index => $item) {
                if (! is_array($item) || ! isset($item['menu_item_id'])) {
                    continue;
                }

                if (! in_array((int) $item['menu_item_id'], $restaurantMenuItemIds, true)) {
                    $validator->errors()->add(
                        "items.$index.menu_item_id",
                        'The selected menu item is not available from this restaurant.'
                    );
                }
            }
        });
    }

    public function messages(): array
    {
        return [
            'restaurant_id.required' => 'Choose a restaurant before checkout.',
            'restaurant_id.in' => 'The selected restaurant is unavailable.',
            'items.required' => 'Add at least one menu item before checkout.',
            'items.array' => 'Add at least one menu item before checkout.',
            'items.min' => 'Add at least one menu item before checkout.',
            'items.*.menu_item_id.required' => 'Choose a menu item before checkout.',
            'items.*.menu_item_id.in' => 'The selected menu item is unavailable.',
            'items.*.quantity.required' => 'Quantity must be at least 1.',
            'items.*.quantity.integer' => 'Quantity must be a whole number.',
            'items.*.quantity.min' => 'Quantity must be at least 1.',
            'items.*.quantity.max' => 'Quantity cannot exceed 10.',
            'payment_method.required' => 'Choose a payment method.',
            'payment_method.in' => 'Choose a supported payment method.',
            'delivery_address.required' => 'Enter a delivery address before checkout.',
            'delivery_address.array' => 'Enter a delivery address before checkout.',
            'delivery_address.label.required' => 'Enter a delivery address before checkout.',
        ];
    }
}
