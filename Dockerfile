FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set Composer timeout dan memory
RUN composer config --global process-timeout 2000

WORKDIR /var/www

# Copy hanya file yang diperlukan untuk install dependencies dulu
COPY composer.json composer.lock ./

# Install dependencies (dengan fallback jika gagal)
RUN composer install --no-interaction --optimize-autoloader --no-dev || \
    composer install --no-interaction --optimize-autoloader --no-dev --prefer-dist

# Copy sisa file
COPY . .

# Install Node dependencies dan build
RUN npm install && npm run build || \
    npm install --legacy-peer-deps && npm run build

# Permission setup
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

USER www-data

EXPOSE 9000
CMD ["php-fpm"]