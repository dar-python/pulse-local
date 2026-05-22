<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class LandingPageTest extends TestCase
{
    public function test_root_page_documents_current_foodpulse_prediction_flow(): void
    {
        Http::preventStrayRequests();

        $response = $this->get('/');

        $response->assertOk()
            ->assertSee('FoodPulse')
            ->assertSee('href="/landing/foodpulse.css"', false)
            ->assertSee('src="/landing/images/logoeagle.png"', false)
            ->assertSee('href="/api/health"', false)
            ->assertSee('Real-Time Weather Enrichment')
            ->assertSee(
                'During checkout, Laravel enriches the request with current weather data from the configured weather API before forwarding normalized features to the ML service.'
            )
            ->assertSee('delivery_latitude')
            ->assertSee('delivery_longitude')
            ->assertSee('Flutter calls Laravel only.')
            ->assertSee('/api/checkout/risk', false)
            ->assertSee('92.0%')
            ->assertSee('93.33%')
            ->assertSee('94.74%')
            ->assertSee('94.03%')
            ->assertSee('0.9777')
            ->assertSee('0.9669')
            ->assertSee('0.0053')
            ->assertSee('FoodPulse | Zuniega Docil © 2026')
            ->assertDontSee('88.4%')
            ->assertDontSee('85.7%')
            ->assertDontSee('0.91');
    }

    public function test_landing_stylesheet_uses_public_eagle_background(): void
    {
        $stylesheet = file_get_contents(public_path('landing/foodpulse.css'));

        $this->assertIsString($stylesheet);
        $this->assertStringContainsString('url("/landing/images/eagle.png")', $stylesheet);
    }

    public function test_health_route_still_returns_laravel_api_json(): void
    {
        $this->getJson('/api/health')
            ->assertOk()
            ->assertExactJson([
                'status' => 'ok',
                'service' => 'laravel-api',
            ]);
    }
}
