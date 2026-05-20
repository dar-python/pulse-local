<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class MobileAuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'username' => ['required', 'string', 'max:25', 'regex:/^[A-Za-z0-9._-]+$/', 'unique:users,username'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'contact_number' => ['required', 'string', 'min:10', 'max:11', 'regex:/^[0-9]+$/'],
            'password' => ['required', 'string', 'min:6', 'max:15', 'regex:/^[A-Za-z0-9!@#$%^&*._-]+$/'],
        ]);

        $user = User::create([
            'name' => $validated['username'],
            'email' => $validated['email'],
            'username' => $validated['username'],
            'contact_number' => $validated['contact_number'],
            'password' => $validated['password'],
            'role' => 'customer',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Account created.',
            'user' => $this->serializeUser($user),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'username' => ['required', 'string', 'max:25'],
            'password' => ['required', 'string', 'max:15'],
        ]);

        $user = User::query()
            ->where('username', $validated['username'])
            ->where('role', 'customer')
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'username' => ['Invalid account credentials.'],
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'user' => $this->serializeUser($user),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'username' => ['required', 'string', 'max:25'],
            'password' => ['required', 'string', 'max:15'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email,' . $this->customerIdFor($request)],
            'contact_number' => ['required', 'string', 'min:10', 'max:11', 'regex:/^[0-9]+$/'],
        ]);

        $user = $this->verifiedCustomer(
            username: $validated['username'],
            password: $validated['password'],
        );

        $user->update([
            'email' => $validated['email'],
            'contact_number' => $validated['contact_number'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated.',
            'user' => $this->serializeUser($user),
        ]);
    }

    public function updatePassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'username' => ['required', 'string', 'max:25'],
            'current_password' => ['required', 'string', 'max:15'],
            'password' => ['required', 'string', 'min:6', 'max:15', 'regex:/^[A-Za-z0-9!@#$%^&*._-]+$/'],
        ]);

        $user = $this->verifiedCustomer(
            username: $validated['username'],
            password: $validated['current_password'],
        );

        $user->update([
            'password' => $validated['password'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password updated.',
            'user' => $this->serializeUser($user),
        ]);
    }

    private function verifiedCustomer(string $username, string $password): User
    {
        $user = User::query()
            ->where('username', $username)
            ->where('role', 'customer')
            ->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'password' => ['Current account credentials are invalid.'],
            ]);
        }

        return $user;
    }

    private function customerIdFor(Request $request): ?int
    {
        $username = $request->input('username');
        if (! is_string($username) || $username === '') {
            return null;
        }

        return User::query()
            ->where('username', $username)
            ->where('role', 'customer')
            ->value('id');
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeUser(User $user): array
    {
        return [
            'id' => $user->id,
            'username' => $user->username,
            'name' => $user->name,
            'email' => $user->email,
            'contact_number' => $user->contact_number,
        ];
    }
}
