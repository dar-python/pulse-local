<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AdminModelMetadataTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_fetch_model_metadata_from_ml_service(): void
    {
        config([
            'services.ml_service.url' => 'http://ml-service:8001',
            'services.ml_service.timeout' => 3,
        ]);

        Http::fake([
            'http://ml-service:8001/metadata' => Http::response($this->metadataPayload()),
        ]);

        $response = $this->actingAs($this->adminUser())
            ->getJson('/api/admin/model-metadata');

        $response->assertOk()
            ->assertJson([
                'data' => [
                    'model_name' => 'PulseLocal Logistic Regression Fulfillment Risk Model',
                    'model_type' => 'LogisticRegression',
                    'target_column' => 'is_fulfillment_risky',
                    'features' => ['Distance_km', 'Weather'],
                    'numeric_features' => ['Distance_km'],
                    'categorical_features' => ['Weather'],
                    'risk_thresholds' => [
                        'low' => ['min' => 0.0, 'max' => 0.39],
                        'medium' => ['min' => 0.4, 'max' => 0.69],
                        'high' => ['min' => 0.7, 'max' => 1.0],
                    ],
                    'test_metrics' => [
                        'accuracy' => 0.92,
                        'precision' => 0.9466,
                        'recall' => 0.9323,
                        'f1_score' => 0.9394,
                        'roc_auc' => 0.9796,
                    ],
                    'cross_validation' => [
                        'method' => 'StratifiedKFold',
                        'n_splits' => 5,
                        'mean_roc_auc' => 0.9767,
                        'std_roc_auc' => 0.0051,
                        'scores' => [0.9737, 0.9686],
                    ],
                    'ml_service' => [
                        'status' => 'available',
                    ],
                ],
            ])
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace');

        $this->assertSame(['data'], array_keys($response->json()));
        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/metadata');
    }

    public function test_super_admin_can_fetch_model_metadata_from_ml_service(): void
    {
        Http::fake([
            'http://127.0.0.1:8001/metadata' => Http::response($this->metadataPayload()),
        ]);

        $this->actingAs($this->adminUser('super_admin'))
            ->getJson('/api/admin/model-metadata')
            ->assertOk()
            ->assertJsonPath('data.ml_service.status', 'available');
    }

    public function test_customer_cannot_fetch_model_metadata(): void
    {
        $this->actingAs($this->adminUser('customer'))
            ->getJson('/api/admin/model-metadata')
            ->assertForbidden()
            ->assertJson([
                'message' => 'Forbidden.',
            ]);
    }

    public function test_unauthenticated_user_cannot_fetch_model_metadata(): void
    {
        $this->getJson('/api/admin/model-metadata')
            ->assertUnauthorized()
            ->assertJson([
                'message' => 'Unauthenticated.',
            ]);
    }

    public function test_admin_endpoint_handles_ml_service_timeout_safely(): void
    {
        config([
            'app.debug' => true,
            'services.ml_service.url' => 'http://ml-service:8001',
            'services.ml_service.timeout' => 1,
        ]);

        Http::fake(fn () => throw new ConnectionException('cURL error 28: Operation timed out'));

        $response = $this->actingAs($this->adminUser())
            ->getJson('/api/admin/model-metadata');

        $response->assertStatus(503)
            ->assertJson([
                'data' => [
                    'ml_service' => [
                        'status' => 'unavailable',
                    ],
                ],
                'message' => 'Model metadata is temporarily unavailable.',
            ])
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace')
            ->assertJsonMissingPath('ml_service_url');

        $this->assertSame(['data', 'message'], array_keys($response->json()));
    }

    private function adminUser(string $role = 'admin'): User
    {
        return User::factory()->create([
            'role' => $role,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function metadataPayload(): array
    {
        return [
            'model_name' => 'PulseLocal Logistic Regression Fulfillment Risk Model',
            'model_type' => 'LogisticRegression',
            'target_column' => 'is_fulfillment_risky',
            'features' => ['Distance_km', 'Weather'],
            'numeric_features' => ['Distance_km'],
            'categorical_features' => ['Weather'],
            'risk_thresholds' => [
                'low' => ['min' => 0.0, 'max' => 0.39],
                'medium' => ['min' => 0.4, 'max' => 0.69],
                'high' => ['min' => 0.7, 'max' => 1.0],
            ],
            'test_metrics' => [
                'accuracy' => 0.92,
                'precision' => 0.9466,
                'recall' => 0.9323,
                'f1_score' => 0.9394,
                'roc_auc' => 0.9796,
            ],
            'cross_validation' => [
                'method' => 'StratifiedKFold',
                'n_splits' => 5,
                'mean_roc_auc' => 0.9767,
                'std_roc_auc' => 0.0051,
                'scores' => [0.9737, 0.9686],
            ],
        ];
    }
}
