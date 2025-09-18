# Trailblazer Integration Guide

This guide covers the integration of Trailblazer into the Libreverse Rails application, including setup, usage patterns, and integration with existing authorization (Rolify + CanCanCan) and authentication (Rodauth) systems.

## Overview

Trailblazer is a framework for structuring business logic in Rails applications. It provides Operations as a way to encapsulate complex workflows, validations, and callbacks, helping to keep controllers and models lean.

## Installation

Trailblazer and Reform (for contracts) have been added to the Gemfile:

```ruby
gem "trailblazer"
gem "reform"
```

Run `bundle install` to install them.

## Basic Usage

### Creating an Operation

Operations inherit from `Trailblazer::Operation` and define steps using the `step` method.

```ruby
class User::Create < Trailblazer::Operation
  step :validate
  step :create_user
  step :send_welcome_email

  def validate(ctx, params:, **)
    contract = UserContract.new
    contract.validate(params[:user])
    ctx[:contract] = contract
    contract.errors.empty?
  end

  def create_user(ctx, **)
    ctx[:user] = User.create(ctx[:contract].values)
  end

  def send_welcome_email(ctx, **)
    UserMailer.welcome(ctx[:user]).deliver_later
  end
end
```

### Using Contracts with Reform

Contracts handle validation and data processing:

```ruby
class UserContract < Reform::Form
  property :name
  property :email
  property :password

  validates :name, presence: true
  validates :email, presence: true, format: /\A[^@\s]+@[^@\s]+\z/
  validates :password, length: { minimum: 8 }
end
```

### In Controllers

Replace complex controller logic with operation calls:

```ruby
class UsersController < ApplicationController
  def create
    result = User::Create.call(params: params, current_user: current_user)
    if result.success?
      redirect_to result[:user]
    else
      render :new, errors: result[:contract].errors
    end
  end
end
```

## Integration with Rodauth Authentication

Rodauth handles authentication. In Operations, access the current user via the context:

```ruby
class Post::Create < Trailblazer::Operation
  step :authenticate
  step :validate
  step :create_post

  def authenticate(ctx, current_user:, **)
    ctx[:user] = current_user
    current_user.present?
  end

  def validate(ctx, params:, **)
    # Validation logic
  end

  def create_post(ctx, **)
    ctx[:post] = ctx[:user].posts.create(ctx[:contract].values)
  end
end
```

In controllers, pass the current_user from Rodauth:

```ruby
result = Post::Create.call(params: params, current_user: rodauth.rails_account)
```

## Integration with Rolify + CanCanCan Authorization

Use Trailblazer's Policy steps for authorization:

```ruby
class Post::Update < Trailblazer::Operation
  step Policy::Guard(:can_update_post?), fail_fast: true
  step :validate
  step :update_post

  def can_update_post?(ctx, current_user:, **)
    Ability.new(current_user).can?(:update, ctx[:post])
  end

  def validate(ctx, params:, **)
    # Validation
  end

  def update_post(ctx, **)
    ctx[:post].update(ctx[:contract].values)
  end
end
```

Define abilities in CanCanCan as usual:

```ruby
class Ability
  include CanCan::Ability

  def initialize(user)
    can :update, Post do |post|
      post.user == user || user.has_role?(:moderator)
    end
  end
end
```

## Advanced Patterns

### Nested Operations

Operations can call other operations:

```ruby
class Order::Process < Trailblazer::Operation
  step :validate_order
  step Subprocess(Payment::Process)
  step Subprocess(Shipping::Schedule)
  step :send_confirmation
end
```

### Error Handling

Use fail steps for error handling:

```ruby
class User::Register < Trailblazer::Operation
  step :validate
  fail :log_error
  step :create_user

  def log_error(ctx, **)
    Rails.logger.error("Registration failed: #{ctx[:contract].errors.full_messages}")
  end
end
```

### Testing

Test operations directly:

```ruby
RSpec.describe User::Create do
  it "creates a user" do
    params = { user: { name: "Test", email: "test@example.com" } }
    result = described_class.call(params: params)
    expect(result.success?).to be true
    expect(result[:user]).to be_persisted
  end
end
```

## When to Use Trailblazer

Use Operations for:
- Complex multi-step business processes
- Workflows requiring validation, authorization, and callbacks
- Replacing fat controllers or service objects
- Scenarios with conditional logic or error handling

Keep simple CRUD in controllers for straightforward cases.

## File Organization

Place operations in `app/operations/` with namespacing:

```
app/operations/
  user/
    create.rb
    update.rb
  post/
    create.rb
    publish.rb
```

## Migration Strategy

Start by converting complex controller actions to Operations gradually. Existing Rolify/CanCanCan abilities and Rodauth authentication will work seamlessly within the new structure.