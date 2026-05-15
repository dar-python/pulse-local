<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CheckoutRiskRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'rider_to_order_ratio' => ['required', 'numeric', 'between:0,1'],
            'merchant_prep_time' => ['required', 'integer', 'min:0'],
            'traffic_level' => ['required', 'string', 'in:light,moderate,heavy'],
            'weather_category' => ['required', 'string', 'in:clear,rainy,stormy'],
            'delivery_distance_km' => ['required', 'numeric', 'min:0'],
            'payment_method' => ['required', 'string', 'in:cod,prepaid'],
        ];
    }
}
