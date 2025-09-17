# Laravel Development Autocompletion Setup Guide

Your Laravel.nvim and blade-nav.nvim plugins are now configured and ready to use! Here's what you have:

## ✅ Configured Features

### 1. **Autocompletion Sources**

- **Routes**: Completion for route names and parameters
- **Views**: Blade template completion
- **Config**: Laravel config key completion
- **Environment Variables**: .env file variable completion
- **Model Columns**: Database column completion for models
- **Blade Components**: Completion for Blade components and Livewire components
- **Blade Navigation**: Smart navigation for @extends, @include, <x-components>, etc.

### 2. **Key Bindings**

- `<leader>ll` - Open Laravel Picker (main menu)
- `<leader>la` - Open Artisan Picker
- `<leader>lr` - Open Routes Picker
- `<leader>lm` - Open Make Picker (create new files)
- `<leader>lc` - Open Commands Picker
- `<leader>lo` - Open Resources Picker
- `<leader>lp` - Open Command Center
- `<leader>lt` - Open Actions Picker
- `<leader>lh` - Open Laravel Documentation
- `<c-g>` - Open View Finder
- `gf` - Enhanced go-to-file for Laravel resources + Blade navigation

### 3. **Completion Configuration**

- Laravel completion is enabled with **high priority** (score_offset: 95)
- Blade-nav completion is enabled with **high priority** (score_offset: 90)
- Compatible with your existing blink.cmp setup
- Integrates blade-nav for enhanced Blade template completion and navigation

## 🚀 How to Use Autocompletion

### Routes

```php
// Type and get completion for route names
route('user.profile') // Will suggest available routes
```

### Views

```php
// Get completion for Blade templates
view('auth.login') // Will suggest available views
return view('dashboard.') // Will suggest views in dashboard folder
```

### Config

```php
// Get completion for config keys
config('app.name') // Will suggest config keys
config('database.') // Will suggest nested config keys
```

### Environment Variables

```php
// Get completion for .env variables
env('APP_URL') // Will suggest variables from .env
```

### Model Columns

```php
// In model files, get completion for database columns
$user->name // Will suggest actual database columns
```

### Blade Components & Navigation (blade-nav.nvim)

```blade
{{-- Blade template completion and navigation --}}
@extends('') {{-- Type inside quotes for layout completion --}}
@include('') {{-- Type inside quotes for partial completion --}}

{{-- Component completion --}}
<x- {{-- Will suggest available Blade components --}}
<livewire: {{-- Will suggest Livewire components --}}
@livewire('') {{-- Type inside quotes for Livewire completion --}}

{{-- Navigation with gf command --}}
{{-- Place cursor on any of these and press 'gf' to navigate: --}}
@extends('layouts.app') {{-- Navigate to layout --}}
@include('partials.header') {{-- Navigate to partial --}}
<x-alert type="success" /> {{-- Navigate to component --}}
<livewire:user-profile /> {{-- Navigate to Livewire component --}}
```

```php
// In controllers and routes - completion and navigation
route('user.profile') // Complete route names + navigate with gf
to_route('dashboard') // Complete route names + navigate with gf
view('auth.login') // Complete view names + navigate with gf
View::make('emails.welcome') // Complete view names + navigate with gf
Route::view('/', 'welcome') // Complete view names + navigate with gf

// Config navigation
config('app.name') // Navigate to config file with gf
```

## 🛠 Additional Features

### Virtual Information

- **Model Info**: Shows database table and field information directly in your model files
- **Route Info**: Displays URI, method, and middleware information above controller methods
- **Composer Info**: Shows package versions and update availability

### Pickers

Use the key bindings above to access powerful Laravel-specific pickers for:

- Running Artisan commands
- Browsing routes
- Creating new files (controllers, models, migrations, etc.)
- Managing resources

## 🔧 Configuration Notes

- **LSP Server**: Currently using `phpactor` (you can change to `intelephense` in php.lua)
- **Picker Provider**: Using `snacks` (you can change to `telescope` or `fzf-lua`)
- **Completion**: Enabled with blink.cmp integration
- **File Navigation**: Enhanced `gf` for Laravel resource navigation + Blade components
- **Blade Navigation**: Smart component detection and navigation with blade-nav.nvim

## 📝 Tips

### Laravel.nvim Tips

1. **Make sure you're in a Laravel project** - The completion works best when you're in a Laravel project root
2. **Run Laravel commands** - Use `<leader>la` to access Artisan commands directly from Neovim
3. **Create files quickly** - Use `<leader>lm` to create controllers, models, migrations, etc.
4. **Browse routes** - Use `<leader>lr` to see all your application routes

### blade-nav.nvim Tips

5. **Use `gf` for navigation** - Place cursor on any Laravel reference and press `gf` to navigate
6. **Create missing components** - If a component doesn't exist, blade-nav will offer to create it
7. **Blade completion shortcuts** - Type `@extends('`, `@include('`, or `<x-` for instant completion
8. **Health check** - Run `:checkhealth blade-nav` to verify plugin status
9. **Install Artisan command** - Run `:BladeNavInstallArtisanCommand` for enhanced functionality

### Workflow Examples

- **Navigate layouts**: `@extends('layouts.app')` → cursor on 'layouts.app' → press `gf`
- **Find components**: `<x-alert` → get completion → press `gf` to view/edit component
- **Route navigation**: `route('user.profile')` → cursor on route name → press `gf` to see controller
- **Config files**: `config('app.name')` → cursor on 'app' → press `gf` to open config file

Your setup is complete and ready to enhance your Laravel development experience!
