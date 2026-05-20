<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\AdminUserSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_page_is_available(): void
    {
        $response = $this->get('/admin/login');

        $response->assertOk()
            ->assertSee('PulseLocal Admin')
            ->assertSee('Username')
            ->assertSee('Password');
    }

    public function test_admin_accounts_are_seeded_with_hashed_passwords(): void
    {
        app(AdminUserSeeder::class)->run();

        $admin = User::where('username', 'admin')->first();
        $superAdmin = User::where('username', 'superadmin')->first();

        $this->assertNotNull($admin);
        $this->assertNotNull($superAdmin);
        $this->assertSame('admin', $admin->role);
        $this->assertSame('super_admin', $superAdmin->role);
        $this->assertTrue(Hash::check('admin123', $admin->password));
        $this->assertTrue(Hash::check('superadmin123', $superAdmin->password));
        $this->assertNotSame('admin123', $admin->password);
        $this->assertNotSame('superadmin123', $superAdmin->password);
    }

    public function test_dashboard_requires_admin_login(): void
    {
        $this->get('/admin/dashboard')
            ->assertRedirect('/admin/login');
    }

    public function test_admin_can_login_and_sees_locked_settings(): void
    {
        app(AdminUserSeeder::class)->run();

        $this->post('/admin/login', [
            'username' => 'admin',
            'password' => 'admin123',
        ])->assertRedirect('/admin/dashboard');

        $this->get('/admin/dashboard?section=settings')
            ->assertOk()
            ->assertSee('System Administration Dashboard')
            ->assertSee('Admin')
            ->assertSee('These controls require Super Admin access')
            ->assertSee('disabled', false);
    }

    public function test_super_admin_can_login_and_access_settings_controls(): void
    {
        app(AdminUserSeeder::class)->run();

        $this->post('/admin/login', [
            'username' => 'superadmin',
            'password' => 'superadmin123',
        ])->assertRedirect('/admin/dashboard');

        $this->get('/admin/dashboard?section=settings')
            ->assertOk()
            ->assertSee('Super Admin')
            ->assertSee('Save All Settings')
            ->assertDontSee('These controls require Super Admin access');
    }

    public function test_dashboard_bootstraps_live_model_metadata_panel(): void
    {
        app(AdminUserSeeder::class)->run();

        $this->post('/admin/login', [
            'username' => 'admin',
            'password' => 'admin123',
        ])->assertRedirect('/admin/dashboard');

        $this->get('/admin/dashboard?section=analytics')
            ->assertOk()
            ->assertSee('Trained Model Metadata')
            ->assertSee('data-model-metadata-panel', false)
            ->assertSee('api\\/admin\\/model-metadata', false)
            ->assertSee('metadataEndpoint');
    }

    public function test_logout_invalidates_admin_session(): void
    {
        app(AdminUserSeeder::class)->run();

        $this->post('/admin/login', [
            'username' => 'admin',
            'password' => 'admin123',
        ])->assertRedirect('/admin/dashboard');

        $this->post('/admin/logout')
            ->assertRedirect('/admin/login');

        $this->get('/admin/dashboard')
            ->assertRedirect('/admin/login');
    }
}
