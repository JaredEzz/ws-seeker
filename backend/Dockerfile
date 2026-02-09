# Use the official Dart image as the build environment
FROM dart:stable AS build

# Set the working directory
WORKDIR /app

# Copy the pubspec files first to cache dependencies
# We need to preserve the directory structure for the monorepo
COPY shared/pubspec.yaml shared/
COPY backend/pubspec.yaml backend/

# Get dependencies for shared
WORKDIR /app/shared
RUN dart pub get

# Get dependencies for backend
WORKDIR /app/backend
RUN dart pub get

# Copy the rest of the source code
COPY shared/ /app/shared/
COPY backend/ /app/backend/

# Build the backend server
WORKDIR /app/backend
RUN dart compile exe bin/server.dart -o bin/server

# Create a minimal runtime image
FROM scratch

# Copy the compiled executable and any necessary system libraries (if needed)
# Dart executables are self-contained, but sometimes need ca-certificates
COPY --from=build /runtime/ /
COPY --from=build /app/backend/bin/server /app/bin/server

# Copy .env file if we were using it, but we'll use Cloud Run env vars instead

# Expose the port
EXPOSE 8080

# Start the server
CMD ["/app/bin/server"]
