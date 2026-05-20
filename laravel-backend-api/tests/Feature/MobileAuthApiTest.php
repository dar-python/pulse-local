<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MobileAuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_register_and_login(): void
    {
        $registerResponse = $this->postJson('/api/auth/register', [
            'username' => 'mobile_user',
            'email' => 'mobile@example.com',
            'contact_number' => '09175550123',
            'password' => 'pass123',
        ]);

        $registerResponse
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('user.username', 'mobile_user')
            ->assertJsonPath('user.contact_number', '09175550123');

        $this->assertDatabaseHas('users', [
            'username' => 'mobile_user',
            'email' => 'mobile@example.com',
            'contact_number' => '09175550123',
            'role' => 'customer',
        ]);

        $loginResponse = $this->postJson('/api/auth/login', [
            'username' => 'mobile_user',
            'password' => 'pass123',
        ]);

        $loginResponse
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('user.username', 'mobile_user');

        $profileResponse = $this->putJson('/api/auth/profile', [
            'username' => 'mobile_user',
            'password' => 'pass123',
            'email' => 'updated-mobile@example.com',
            'contact_number' => '09175550124',
        ]);

        $profileResponse
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('user.email', 'updated-mobile@example.com')
            ->assertJsonPath('user.contact_number', '09175550124');

        $passwordResponse = $this->putJson('/api/auth/password', [
            'username' => 'mobile_user',
            'current_password' => 'pass123',
            'password' => 'newpass123',
        ]);

        $passwordResponse
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->postJson('/api/auth/login', [
            'username' => 'mobile_user',
            'password' => 'newpass123',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);
    }
}
