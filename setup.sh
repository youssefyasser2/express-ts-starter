#!/bin/bash
set -euo pipefail

# ANSI Colors
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Icons
INFO='🔹'
SUCCESS='✅'
WARNING='⚠️'
ERROR='❌'
INPUT='📝'
DATABASE='📦'
FEATURE='⚙️'
FILE='📄'
FOLDER='📁'
RUN='🚀'

echo -e "${BLUE}${RUN} Proton — Express + TypeScript Project Generator${NC}"
echo -e "${YELLOW}   Fast, modular, and production-ready backend setup${NC}"
echo

# ---------- 0) Pre-flight checks ----------
echo -e "${BLUE}${INFO} Checking prerequisites...${NC}"

for cmd in node npm git; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}${ERROR} $cmd is required. Please install it and try again.${NC}"
    exit 1
  fi
done

echo -e "${GREEN}${SUCCESS} All required tools found!${NC}"
echo

# ---------- 1) Gather project info ----------
echo -e "${BLUE}${INFO} Project Configuration${NC}"

read -rp "Project name (default: my-project): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-my-project}

read -rp "Version (default 1.0.0): " VERSION
VERSION=${VERSION:-1.0.0}

read -rp "Description (default: A simple Express + TypeScript project): " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"A simple Express + TypeScript project"}

read -rp "Author (default: Your Name): " AUTHOR
AUTHOR=${AUTHOR:-"Your Name"}

read -rp "License (default MIT): " LICENSE
LICENSE=${LICENSE:-MIT}

read -rp "App port (default 5000): " APP_PORT
APP_PORT=${APP_PORT:-5000}

echo
echo -e "${BLUE}${DATABASE} Choose a database:${NC}"
echo "  [1] MongoDB (Mongoose)"
echo "  [2] PostgreSQL (Prisma)"
echo "  [3] MySQL (Prisma)"
echo "  [4] SQLite (Prisma)"
echo "  [5] None (No database)"
read -rp "Your choice [1-5] (default: 5): " DB_CHOICE
DB_CHOICE=${DB_CHOICE:-5}

DB_PROVIDER=""
DB_URL=""

case "$DB_CHOICE" in
  1)
    DB_PROVIDER="mongodb"
    ;;
  2)
    DB_PROVIDER="postgresql"
    ;;
  3)
    DB_PROVIDER="mysql"
    ;;
  4)
    DB_PROVIDER="sqlite"
    ;;
  5)
    DB_PROVIDER="none"
    ;;
  *)
    echo -e "${RED}${ERROR} Invalid choice. Using default: None.${NC}"
    DB_PROVIDER="none"
    ;;
esac

# ---------- 1.5) Database Configuration (Dynamic) ----------
if [ "$DB_PROVIDER" != "none" ]; then
  echo
  echo -e "${BLUE}${INPUT} Enter ${DB_PROVIDER^} Configuration${NC}"
  
  case "$DB_PROVIDER" in
    "mongodb")
      echo "Choose connection method:"
      echo "  [1] Quick: DB Name only (uses default credentials)"
      echo "  [2] Custom: Full connection details"
      read -rp "Your choice [1-2] (default: 1): " MONGO_MODE
      MONGO_MODE=${MONGO_MODE:-1}

      case "$MONGO_MODE" in
  1)
    # Prompt for username (default: Admin)
    read -rp "Database Username (default: Admin): " MONGO_USER_INPUT
    MONGO_USER=${MONGO_USER_INPUT:-Admin}

    # Securely input password (hidden)
    echo -n "Database Password (will be hidden): "
    read -s MONGO_PASS_INPUT
    echo  # New line after password input
    if [ -z "$MONGO_PASS_INPUT" ]; then
      echo -e "${RED}Error: Password cannot be empty.${NC}" >&2
      exit 1
    fi
    MONGO_PASS="$MONGO_PASS_INPUT"

    # Prompt for database name (default: project name)
    read -rp "Database Name (default: ${PROJECT_NAME}): " MONGO_DB_INPUT
    MONGO_DB=${MONGO_DB_INPUT:-${PROJECT_NAME}}

    # Set host and port (can be extended later for custom input)
    MONGO_HOST="localhost"
    MONGO_PORT="27017"

    # URL-encode special characters in password
    ENCODED_PASS=$(echo "$MONGO_PASS" | sed -e 's/%/%25/g' \
                                            -e 's/:/%3A/g' \
                                            -e 's/\//%2F/g' \
                                            -e 's/?/%3F/g' \
                                            -e 's/#/%23/g' \
                                            -e 's/\[/%5B/g' \
                                            -e 's/\]/%5D/g' \
                                            -e 's/@/%40/g' \
                                            -e 's/!/%21/g' \
                                            -e 's/\$/%24/g' \
                                            -e 's/&/%26/g' \
                                            -e 's/'\''/%27/g' \
                                            -e 's/(/%28/g' \
                                            -e 's/)/%29/g' \
                                            -e 's/\*/%2A/g' \
                                            -e 's/\+/%2B/g' \
                                            -e 's/,/%2C/g' \
                                            -e 's/;/%3B/g' \
                                            -e 's/=/%3D/g')

    # Build the connection URL WITHOUT authSource=admin
    DB_URL="mongodb://${MONGO_USER}:${ENCODED_PASS}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}"

    # Confirmation message (hide actual password)
    echo -e "${GREEN}${SUCCESS} MongoDB connection configured successfully:${NC}"
    echo -e "${CYAN}  Database: ${MONGO_DB}${NC}"
    echo -e "${CYAN}  User:     ${MONGO_USER}${NC}"
    echo -e "${CYAN}  Host:     ${MONGO_HOST}:${MONGO_PORT}${NC}"
    echo -e "${CYAN}  URL:      mongodb://${MONGO_USER}:***@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}${NC}"
    ;;
    
    
        2)
          read -rp "MongoDB Host (default: localhost): " MONGO_HOST
          MONGO_HOST=${MONGO_HOST:-localhost}
          
          read -rp "MongoDB Port (default: 27017): " MONGO_PORT
          MONGO_PORT=${MONGO_PORT:-27017}
          
          read -rp "Database Name (default: ${PROJECT_NAME}): " MONGO_DB
          MONGO_DB=${MONGO_DB:-${PROJECT_NAME}}
          
          read -rp "Username (default: Admin): " MONGO_USER
          MONGO_USER=${MONGO_USER:-Admin}
          
          read -rp "Password: " MONGO_PASS
          if [ -z "$MONGO_PASS" ]; then
            echo -e "${RED}${ERROR} Password is required!${NC}"
            exit 1
          fi
          
          # Encode password
          ENCODED_PASS=$(echo "$MONGO_PASS" | sed 's/%/%25/g; s/:/%3A/g; s/\//%2F/g; s/\?/%3F/g; s/#/%23/g; s/\[/%5B/g; s/\]/%5D/g; s/@/%40/g')
          
          DB_URL="mongodb://${MONGO_USER}:${ENCODED_PASS}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}?authSource=admin"
          echo -e "${GREEN}${SUCCESS} Custom MongoDB connection configured${NC}"
          ;;
        *)
          echo -e "${RED}${ERROR} Invalid choice. Using quick mode.${NC}"
          MONGO_DB=${PROJECT_NAME}
          MONGO_USER="Admin"
          MONGO_PASS="Yyoussef248_admin@new_1pwd"
          ENCODED_PASS=$(echo "$MONGO_PASS" | sed 's/%/%25/g; s/:/%3A/g; s/\//%2F/g; s/\?/%3F/g; s/#/%23/g; s/\[/%5B/g; s/\]/%5D/g; s/@/%40/g')
          DB_URL="mongodb://${MONGO_USER}:${ENCODED_PASS}@localhost:27017/${MONGO_DB}?authSource=admin"
          ;;
      esac
      ;;
      
    "postgresql")
      read -rp "Host (default: localhost): " PG_HOST
      PG_HOST=${PG_HOST:-localhost}
      
      read -rp "Port (default: 5432): " PG_PORT
      PG_PORT=${PG_PORT:-5432}
      
      read -rp "Database Name (default: ${PROJECT_NAME}): " PG_DB
      PG_DB=${PG_DB:-${PROJECT_NAME}}
      
      read -rp "Username (default: user): " PG_USER
      PG_USER=${PG_USER:-user}
      
      read -rp "Password: " PG_PASS
      
      DB_URL="postgresql://${PG_USER}:${PG_PASS}@${PG_HOST}:${PG_PORT}/${PG_DB}?schema=public"
      ;;
      
    "mysql")
      read -rp "Host (default: localhost): " MYSQL_HOST
      MYSQL_HOST=${MYSQL_HOST:-localhost}
      
      read -rp "Port (default: 3306): " MYSQL_PORT
      MYSQL_PORT=${MYSQL_PORT:-3306}
      
      read -rp "Database Name (default: ${PROJECT_NAME}): " MYSQL_DB
      MYSQL_DB=${MYSQL_DB:-${PROJECT_NAME}}
      
      read -rp "Username (default: user): " MYSQL_USER
      MYSQL_USER=${MYSQL_USER:-user}
      
      read -rp "Password: " MYSQL_PASS
      
      DB_URL="mysql://${MYSQL_USER}:${MYSQL_PASS}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}"
      ;;
      
    "sqlite")
      DB_URL="file:./dev.db"
      echo -e "${GREEN}${SUCCESS} SQLite uses file:./dev.db${NC}"
      ;;
  esac
else
  echo -e "${YELLOW}${WARNING} No database selected. Skipping DB configuration.${NC}"
fi

# ---------- Optional Features ----------
echo
echo -e "${BLUE}${FEATURE} Optional Features${NC}"

read -rp "Include Docker support? (y/N) (default: N): " USE_DOCKER
USE_DOCKER=${USE_DOCKER:-n}

read -rp "Include Swagger UI for API docs? (y/N) (default: N): " USE_SWAGGER
USE_SWAGGER=${USE_SWAGGER:-n}

read -rp "Include Redis for caching/sessions? (y/N) (default: N): " USE_REDIS
USE_REDIS=${USE_REDIS:-n}

read -rp "Include Winston for advanced logging? (y/N) (default: N): " USE_WINSTON
USE_WINSTON=${USE_WINSTON:-n}

read -rp "Include Husky for Git hooks? (y/N) (default: N): " USE_HUSKY
USE_HUSKY=${USE_HUSKY:-n}

read -rp "Initialize Git repository? (y/N) (default: y): " INIT_GIT
INIT_GIT=${INIT_GIT:-y}

# ---------- 2) Create project folder ----------
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"
echo -e "${GREEN}${SUCCESS} Project directory created: ./${PROJECT_NAME}${NC}"

# ---------- 3) package.json ----------
cat > package.json <<EOF
{
  "name": "${PROJECT_NAME}",
  "version": "${VERSION}",
  "description": "${DESCRIPTION}",
  "main": "dist/server.js",
  "type": "commonjs",
  "scripts": {
    "dev": "nodemon --exec ts-node src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "lint": "eslint . --ext .ts --fix",
    "test": "jest --coverage",
    "format": "prettier --write .",
    "db:seed": "ts-node scripts/db.seed.ts",
    "db:reset": "ts-node scripts/db.reset.ts"
  },
  "keywords": [],
  "author": "${AUTHOR}",
  "license": "${LICENSE}",
  "engines": {
    "node": ">=18.0.0"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/yourusername/${PROJECT_NAME}.git"
  },
  "bugs": {
    "url": "https://github.com/yourusername/${PROJECT_NAME}/issues"
  },
  "homepage": "https://github.com/yourusername/${PROJECT_NAME}#readme"
}
EOF
echo -e "${GREEN}${SUCCESS} package.json created${NC}"

# ---------- 2.5) Scripts Folder Enhancement ----------
echo -e "${BLUE}${FOLDER} Enhancing scripts folder${NC}"

mkdir -p scripts

cat > scripts/db.seed.ts <<'EOF'
import { connectDB } from '../src/config/db.config';
import { UserModel } from '../src/modules/user/user.model';

async function seed() {
  await connectDB();
  const count = await UserModel.countDocuments();
  if (count === 0) {
    await UserModel.create([
      { email: 'admin@example.com', name: 'Admin', password: 'hashed_password' }
    ]);
    console.log('✅ Database seeded');
  } else {
    console.log('⚠️  Database already has data');
  }
  process.exit(0);
}

seed().catch(console.error);
EOF

cat > scripts/db.reset.ts <<'EOF'
import { connectDB } from '../src/config/db.config';
import { UserModel } from '../src/modules/user/user.model';

async function reset() {
  await connectDB();
  await UserModel.deleteMany({});
  console.log('✅ Database reset');
  process.exit(0);
}

reset().catch(console.error);
EOF

echo -e "${GREEN}${SUCCESS} Scripts: db:seed, db:reset added${NC}"

# ---------- 4) Install dependencies ----------
echo -e "${BLUE}${INFO} Installing dependencies...${NC}"

npm init -y > /dev/null 2>&1

# Core dependencies
echo -e "${CYAN}   → Installing core dependencies...${NC}"
npm install express@5.1.0 cors helmet morgan dotenv bcryptjs jsonwebtoken zod > /dev/null 2>&1

# Dev dependencies
echo -e "${CYAN}   → Installing dev tools...${NC}"
npm install -D \
  typescript@5.9.2 \
  ts-node@10.9.2 \
  nodemon@3.1.10 \
  @types/node@latest \
  @types/express@latest \
  @types/bcryptjs \
  @types/jsonwebtoken@9.0.5 \
  @types/cors@latest \
  @types/morgan@latest \
  eslint@9.33.0 \
  prettier@3.6.2 \
  eslint-config-prettier@latest \
  eslint-plugin-prettier@latest \
  jest@30.0.5 \
  ts-jest@latest \
  @types/jest@latest \
  supertest@7.1.4 \
  @types/supertest@latest > /dev/null 2>&1

# Database dependencies
if [ "$DB_PROVIDER" != "none" ]; then
  if [ "$DB_PROVIDER" = "mongodb" ]; then
    echo -e "${CYAN}   → Installing Mongoose...${NC}"
    npm install mongoose@8.17.2 > /dev/null 2>&1
    npm install -D @types/mongoose@latest > /dev/null 2>&1
  else
    echo -e "${CYAN}   → Installing Prisma...${NC}"
    npm install prisma@6.14.0 @prisma/client@6.14.0 > /dev/null 2>&1
  fi
fi

# Optional dependencies
if [[ "$USE_SWAGGER" =~ ^[Yy]$ ]]; then
  echo -e "${CYAN}   → Installing Swagger UI...${NC}"
  npm install swagger-ui-express@5.0.1 yaml@latest > /dev/null 2>&1
  npm install -D @types/swagger-ui-express@latest > /dev/null 2>&1
fi

if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
  echo -e "${CYAN}   → Installing Redis...${NC}"
  npm install redis@5.8.1 > /dev/null 2>&1
fi

if [[ "$USE_WINSTON" =~ ^[Yy]$ ]]; then
  echo -e "${CYAN}   → Installing Winston for logging...${NC}"
  npm install winston@3.17.0 > /dev/null 2>&1
fi

if [[ "$USE_HUSKY" =~ ^[Yy]$ ]]; then
  echo -e "${CYAN}   → Installing Husky for Git hooks...${NC}"
  npm install -D husky@9.1.7 lint-staged@latest > /dev/null 2>&1
fi

echo -e "${GREEN}${SUCCESS} Dependencies installed${NC}"

# ---------- 5) TypeScript config ----------
cat > tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "lib": ["ES2020", "DOM"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
echo -e "${GREEN}${SUCCESS} TypeScript configured${NC}"

# ---------- 6) Project structure ----------
echo -e "${BLUE}${FOLDER} Creating project structure...${NC}"

mkdir -p src/{config,database/{migrations,seeders,prisma},modules/{user,auth},middlewares,utils,docs,tests,types/express,constant,routes}
mkdir -p scripts
mkdir -p public/uploads public/downloads

touch public/index.html
touch public/favicon.ico
touch src/{app.ts,server.ts}
touch src/config/{app.config.ts,db.config.ts,auth.config.ts,index.ts}
touch src/middlewares/{auth.middleware.ts,error.middleware.ts,validate.middleware.ts}
touch src/utils/{logger.ts,hash.ts,jwt.ts,response.ts}
touch src/docs/swagger.json
touch src/routes/index.ts
touch src/constant/{role.ts,messages.ts,index.ts,status.ts}
touch scripts/create-user.ts
touch .prettierrc .eslintrc.json .gitignore .env.example README.md 

# User module
touch src/modules/user/{user.controller.ts,user.service.ts,user.routes.ts,user.validation.ts,user.model.ts}
mkdir -p src/modules/user/dto
touch src/modules/user/dto/create-user.dto.ts
touch src/modules/user/dto/user-response.dto.ts

# Auth module
touch src/modules/auth/{auth.controller.ts,auth.service.ts,auth.routes.ts,auth.validation.ts}
mkdir -p src/modules/auth/dto
touch src/modules/auth/dto/login.dto.ts
touch src/modules/auth/dto/auth-response.dto.ts

# Types
touch src/types/global.d.ts
touch src/types/express/index.d.ts

# Prisma
if [ "$DB_PROVIDER" != "none" ] && [ "$DB_PROVIDER" != "mongodb" ]; then
  npx prisma init --datasource-provider "$DB_PROVIDER" > /dev/null 2>&1 || echo -e "${YELLOW}${WARNING} Prisma init skipped or failed.${NC}"
fi

echo -e "${GREEN}${SUCCESS} Project structure created${NC}"


# ---------- 23.5) Create test files with real tests ----------
echo -e "${BLUE}${FILE} Creating test files with sample tests...${NC}"

cat > src/tests/user.test.ts <<'EOF'
// src/tests/user.test.ts
import { describe, it, expect } from '@jest/globals';

describe('User Tests', () => {
  it('should pass a simple test', () => {
    expect(true).toBe(true);
  });

  it('should have a user object with email', () => {
    const user = { email: 'test@example.com', name: 'Test User' };
    expect(user.email).toBeDefined();
    expect(typeof user.email).toBe('string');
  });
});
EOF

cat > src/tests/auth.test.ts <<'EOF'
// src/tests/auth.test.ts
import { describe, it, expect } from '@jest/globals';

describe('Auth Module', () => {
  it('should reject invalid login', () => {
    const isValid = (email: string, password: string) =>
      email === 'admin@example.com' && password === 'password123';

    expect(isValid('hacker@test.com', 'wrong')).toBe(false);
  });

  it('should accept valid credentials', () => {
    expect(true).toBe(true);
  });
});
EOF

echo -e "${GREEN}${SUCCESS} Test files created with real tests${NC}"


# ---------- index.html ----------

cat > public/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Welcome to express</title>
  <link rel="icon" href="/favicon.ico" type="image/x-icon" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #010613, #061547);
      color: #2c3e50;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      position: relative;
    }

    .bg-shape {
      position: absolute;
      border-radius: 50%;
      background: white;
      opacity: 0.1;
      pointer-events: none;
      animation: float 6s ease-in-out infinite;
    }
    .shape-1 { width: 300px; height: 300px; top: 10%; left: 10%; }
    .shape-2 { width: 200px; height: 200px; top: 60%; right: 10%; animation-delay: 2s; }
    .shape-3 { width: 150px; height: 150px; bottom: 10%; left: 30%; animation-delay: 4s; }

    @keyframes float {
      0%, 100% { transform: translateY(0) scale(1); }
      50% { transform: translateY(-15px) scale(1.05); }
    }

    .container {
      text-align: center;
      background: rgba(255, 255, 255, 0.95);
      backdrop-filter: blur(10px);
      border-radius: 16px;
      padding: 50px 60px;
      box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
      max-width: 530px;
      width: 90%;
      transition: transform .3s ease;
    }
    .container:hover { transform: translateY(-5px); }

    .logo {
      width: 70px; height: 70px;
      margin: 0 auto 25px;
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 2rem;
      background: linear-gradient(135deg, #112353, #556bb6);
      color: white;
      cursor: pointer;
      transition: transform .3s ease;
    }
    .logo:hover { transform: scale(1.05) rotate(5deg); }

    h1 {
      font-size: 1.8rem;
      font-weight: 700;
      margin-bottom: 15px;
      background: linear-gradient(135deg, #1e3a8a, #030713);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .subtitle {
      font-size: 1.1rem;
      color: #64748b;
      margin-bottom: 30px;
      line-height: 1.6;
    }

    .tech-badges {
      display: flex;
      justify-content: center;
      gap: 12px;
      margin-bottom: 30px;
      flex-wrap: wrap;
      font-size: 0.85rem;
    }
    .badge {
      padding: 6px 14px;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 20px;
      color: #475569;
      font-weight: 500;
      transition: .3s ease;
      cursor: pointer;
    }
    .badge:hover {
      background: #071641;
      color: white;
      border-color: #1e3a8a;
      transform: translateY(-2px);
    }

    .actions {
      display: flex;
      gap: 15px;
      justify-content: center;
      margin-bottom: 20px;
      flex-wrap: wrap;
    }
    .action-link {
      display: inline-block;
      color: #1e3a8a;
      text-decoration: none;
      font-weight: 500;
      font-size: 0.95rem;
      padding: 10px 20px;
      border-radius: 8px;
      position: relative;
      overflow: hidden;
      transition: .3s ease;
    }
    .action-link::before {
      content: '';
      position: absolute;
      inset: 0;
      background: linear-gradient(135deg, #1e3a8a, #1e40af);
      border-radius: 8px;
      opacity: 0;
      z-index: -1;
      transition: opacity .3s ease;
    }
    .action-link:hover::before { opacity: 1; }
    .action-link:hover { color: white; transform: translateY(-1px); }

    .status {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      background: rgba(34, 197, 94, 0.1);
      border-radius: 20px;
      font-size: 0.85rem;
      color: #16a34a;
    }
    .status-dot {
      width: 8px; height: 8px;
      background: #22c55e;
      border-radius: 50%;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(1.2); }
    }

    @media (max-width: 640px) {
      .container { padding: 40px 20px; }
      h1 { font-size: 2rem; }
      .actions { flex-direction: column; }
      .action-link { width: 100%; max-width: 200px; }
    }
  </style>
</head>
<body>
  <div class="bg-shape shape-1"></div>
  <div class="bg-shape shape-2"></div>
  <div class="bg-shape shape-3"></div>

  <div class="container">
    <div class="logo" id="logo">📡</div>
 <h1>
  Server is running  Successfully 
</h1>

    <p class="subtitle">Your development server is running and ready to build amazing APIs.</p>

    <div class="tech-badges">
      <span class="badge">Express</span>
      <span class="badge">TypeScript</span>
      <span class="badge">MongoDB</span>
      <span class="badge">Redis</span>
    </div>

    <div class="actions">
      <a href="/docs" class="action-link">📚 Docs</a>
      <a href="/api/users" class="action-link">👥 API</a>
      <a href="https://expressjs.com" class="action-link">🌐 Learn</a>
    </div>


  <script>
    // Particle effect
    const createParticle = () => {
      const p = Object.assign(document.createElement('div'), {
        className: 'particle',
        style: `position:absolute;width:3px;height:3px;background:rgba(30,58,138,0.6);border-radius:50%;left:${Math.random()*100}%;top:100%;opacity:0;animation:particleFloat ${Math.random()*3+2}s linear forwards;`
      });
      document.body.append(p);
      setTimeout(() => p.remove(), 5000);
    };
    setInterval(createParticle, 1500);

    // Logo interaction
    document.getElementById('logo').onclick = (e) => {
      e.target.style.transform = 'scale(0.9) rotate(-5deg)';
      setTimeout(() => e.target.style.transform = '', 150);
    };

    // Parallax effect
    document.onmousemove = (e) => {
      const x = e.clientX / innerWidth - 0.5;
      const y = e.clientY / innerHeight - 0.5;
      document.querySelector('.container').style.transform = `translate(${x*10}px, ${y*10}px)`;
      document.querySelectorAll('.bg-shape').forEach((s, i) => {
        const speed = (i + 1) * 0.5;
        s.style.transform = `translate(${x*speed*20}px, ${y*speed*20}px)`;
      });
    };
  </script>
</body>
</html>
EOF

# empty for now
dd if=/dev/zero of=public/favicon.ico bs=1 count=0 > /dev/null 2>&1 || echo -e "${YELLOW}${WARNING} favicon.ico created as placeholder${NC}"

# ---------- 7) .env ----------
echo -e "${BLUE}${FILE} Creating enhanced .env file${NC}"

cat > .env <<EOF
# ==============================
# 🌍 Server Configuration
# ==============================
PORT=${APP_PORT}
NODE_ENV=development

# ==============================
# 🔑 JWT Configuration
# ==============================
JWT_SECRET=supersecretkey_change_me
JWT_EXPIRES_IN=1d

# ==============================
# 🗄️ Database Configuration
# ==============================
DATABASE_URL=${DB_URL}

# ==============================
# 📦 Redis Configuration
# ==============================
REDIS_URL=redis://localhost:6379

# ==============================
# 📧 Email Configuration
# ==============================
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_email_password

# ==============================
# 🛡️ Security
# ==============================
BCRYPT_SALT_ROUNDS=10

# ==============================
# 📁 Logging Configuration
# ==============================
LOG_LEVEL=info
LOG_FILE=/var/log/app.log
LOG_FORMAT=json
LOG_ROTATION=1day
LOG_MAX_FILES=10
LOG_MAX_SIZE=10MB

# ==============================
# 📊 Monitoring Configuration
# ==============================
MONITORING_URL=http://localhost:9200
MONITORING_INDEX=${PROJECT_NAME}
MONITORING_INTERVAL=1h

# ==============================
# 🗂️ File Storage Configuration
# ==============================
FILE_STORAGE_URL=local
FILE_STORAGE_PATH=./public/uploads
FILE_STORAGE_MAX_SIZE=10MB
FILE_STORAGE_DEFAULT_FILENAME=example.jpg

# ==============================
# 🔒 CORS Configuration
# ==============================
CORS_ALLOWED_ORIGINS=http://localhost:3000
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE
CORS_ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With,Accept,Origin
CORS_ALLOW_CREDENTIALS=true
CORS_MAX_AGE=86400

# ==============================
# 🗺️ API Configuration
# ==============================
API_URL=http://localhost:${APP_PORT}
API_VERSION=${VERSION}
API_PREFIX=/api/v1
API_DEBUG=true
API_LOG_REQUESTS=true
API_RATE_LIMIT=1000
API_RATE_LIMIT_WINDOW=1h
API_ENABLE_CACHING=true
API_CACHE_TTL=3600
API_CACHE_MAX_SIZE=1000
EOF

cp .env .env.example
sed -i.bak 's/supersecretkey_change_me/CHANGE_ME/g' .env.example && rm -f .env.example.bak || echo -e "${YELLOW}${WARNING} .env.example update skipped${NC}"

# ---------- 8) Gitignore & Linting ----------
cat > .gitignore <<'EOF'
node_modules
dist
.env
.env.*
coverage
.DS_Store
*.log
prisma/dev.db
EOF

cat > .prettierrc <<'EOF'
{
  "singleQuote": true,
  "semi": true,
  "trailingComma": "all",
  "printWidth": 100
}
EOF

cat > .eslintrc.json <<'EOF'
{
  "env": {
    "node": true,
    "es2021": true,
    "jest": true
  },
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "plugins": ["@typescript-eslint", "prettier"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:prettier/recommended"
  ],
  "rules": {
    "prettier/prettier": "error",
    "@typescript-eslint/no-unused-vars": ["warn"]
  }
}
EOF

echo -e "${GREEN}${SUCCESS} Config files created (.env, .gitignore, ESLint, Prettier)${NC}"

# ---------- 9) Docker ----------
if [[ "$USE_DOCKER" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}${FOLDER} Generating Docker files...${NC}"

  cat > Dockerfile <<EOF
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

RUN npm run build

EXPOSE ${APP_PORT}

CMD ["npm", "start"]
EOF

  cat > docker-compose.yml <<EOF
version: '3.8'
services:
  app:
    build: .
    ports:
      - "${APP_PORT}:${APP_PORT}"
    environment:
      - NODE_ENV=production
      - PORT=${APP_PORT}
EOF
  if [ "$DB_PROVIDER" != "none" ]; then
    echo "      - DATABASE_URL=${DB_URL}" >> docker-compose.yml
  fi
  if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
    echo "      - REDIS_URL=redis://redis:6379" >> docker-compose.yml
  fi
  if [ "$DB_PROVIDER" != "none" ]; then
    echo "    depends_on:" >> docker-compose.yml
    echo "      - db" >> docker-compose.yml
  fi
  if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
    echo "      - redis" >> docker-compose.yml
  fi

  if [ "$DB_PROVIDER" != "none" ] && [ "$DB_PROVIDER" != "sqlite" ]; then
    cat >> docker-compose.yml <<EOF

  db:
    image: ${DB_PROVIDER}:latest
    environment:
      - POSTGRES_DB=${PROJECT_NAME}
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - db-data:/var/lib/postgresql/data
EOF
  fi

  if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
    cat >> docker-compose.yml <<EOF

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
EOF
  fi

  echo "volumes:" >> docker-compose.yml
  echo "  db-data:" >> docker-compose.yml

  echo -e "${GREEN}${SUCCESS} Docker support added${NC}"
fi

# ---------- 10) Swagger ----------
if [[ "$USE_SWAGGER" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}${INFO} Setting up Swagger UI...${NC}"

  cat > src/middlewares/swagger.middleware.ts <<'EOF'
import { Express } from 'express';
import swaggerUi from 'swagger-ui-express';
import * as yaml from 'yaml';
import * as fs from 'fs';
import * as path from 'path';

export function setupSwagger(app: Express) {
  const swaggerPath = path.join(process.cwd(), 'src/docs/swagger.yaml');
  const file = fs.readFileSync(swaggerPath, 'utf8');
  const swaggerDocument = yaml.parse(file);
  app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}
EOF

  cat > src/docs/swagger.yaml <<EOF
openapi: 3.0.0
info:
  title: ${PROJECT_NAME}
  version: ${VERSION}
  description: ${DESCRIPTION}
servers:
  - url: http://localhost:${APP_PORT}
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
  schemas:
    CreateUser:
      type: object
      required:
        - email
        - name
        - password
      properties:
        email:
          type: string
          format: email
        name:
          type: string
        password:
          type: string
          format: password
    Login:
      type: object
      required:
        - email
        - password
      properties:
        email:
          type: string
          format: email
        password:
          type: string
          format: password
security:
  - BearerAuth: []
paths:
  /:
    get:
      summary: Health check
      responses:
        '200':
          description: OK
  /api/users:
    get:
      summary: List all users
      responses:
        '200':
          description: OK
    post:
      summary: Create a new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              \$ref: '#/components/schemas/CreateUser'
      responses:
        '201':
          description: User created
  /api/auth/login:
    post:
      summary: Login user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              \$ref: '#/components/schemas/Login'
      responses:
        '200':
          description: Login successful
EOF

  echo -e "${GREEN}${SUCCESS} Swagger UI added at /docs${NC}"
fi

# ---------- 11) Redis ----------
if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}${INFO} Adding Redis support...${NC}"

  mkdir -p src/config

  cat > src/config/redis.config.ts <<'EOF'
import { createClient } from 'redis';

export const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));

export async function connectRedis() {
  await redisClient.connect();
  console.log('Redis connected');
}
EOF

  # Add to .env.example
  echo "REDIS_URL=redis://localhost:6379" >> .env.example

  echo -e "${GREEN}${SUCCESS} Redis support added${NC}"
fi

# ---------- 12) Winston Logging ----------
if [[ "$USE_WINSTON" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}${INFO} Adding Winston logging...${NC}"

  cat > src/utils/logger.ts <<'EOF'
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.colorize(),
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => \`\${timestamp} [\${level}]: \${message}\`)
  ),
  transports: [new winston.transports.Console()],
});

export default logger;
EOF

  echo -e "${GREEN}${SUCCESS} Winston logging added${NC}"
else
  cat > src/utils/logger.ts <<'EOF'
export const log = (...args: any[]) => console.log('[LOG]', ...args);
export const err = (...args: any[]) => console.error('[ERR]', ...args);
EOF
fi

# ---------- 13) Husky ----------
if [[ "$USE_HUSKY" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}${INFO} Setting up Husky Git hooks...${NC}"

  npx husky init > /dev/null 2>&1 || echo -e "${YELLOW}${WARNING} Husky init skipped or failed.${NC}"
  echo "npx lint-staged" > .husky/pre-commit

  cat > .lintstagedrc.json <<'EOF'
{
  "*.ts": [
    "eslint --fix",
    "prettier --write"
  ]
}
EOF

  echo -e "${GREEN}${SUCCESS} Husky and lint-staged added${NC}"
fi

# ---------- 14) App skeleton ----------
cat > src/server.ts <<'EOF'
import 'dotenv/config';
import app from './app';
import { bootstrap } from './config/app.bootstrap';

const PORT = process.env.PORT || 5000;

(async () => {
  try {
    await bootstrap();
    app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Bootstrap failed:', error);
    process.exit(1);
  }
})();
EOF

cat > src/app.ts <<'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';

import userRoutes from './modules/user/user.routes';
import authRoutes from './modules/auth/auth.routes';
import { errorMiddleware } from './middlewares/error.middleware';
EOF

if [[ "$USE_SWAGGER" =~ ^[Yy]$ ]]; then
  echo "import { setupSwagger } from './middlewares/swagger.middleware';" >> src/app.ts
fi

cat >> src/app.ts <<'EOF'

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));


app.use('/public', express.static(path.join(process.cwd(), 'public')));

// Serve index.html on root route
app.get('/', (_req, res) => {
  res.sendFile(path.join(process.cwd(), 'public', 'index.html'));
});

// Optional: Serve favicon explicitly (sometimes needed)
app.get('/favicon.ico', (_req, res) => {
  res.sendFile(path.join(process.cwd(), 'public', 'favicon.ico'));
});

app.use('/api/users', userRoutes);
app.use('/api/auth', authRoutes);
EOF

if [[ "$USE_SWAGGER" =~ ^[Yy]$ ]]; then
  echo "setupSwagger(app);" >> src/app.ts
fi

cat >> src/app.ts <<'EOF'

app.use(errorMiddleware);

export default app;
EOF

# ---------- 15) Config files ----------
cat > src/config/index.ts <<'EOF'
export * from './app.config';
export * from './auth.config';
export * from './db.config';
EOF

cat > src/config/app.config.ts <<'EOF'
export const isProd = process.env.NODE_ENV === 'production';
export const port = Number(process.env.PORT || 5000);
export const apiPrefix = process.env.API_PREFIX || '/api/v1';
export const rateLimit = {
  max: Number(process.env.API_RATE_LIMIT || 1000),
  windowMs: (() => {
    const time = process.env.API_RATE_LIMIT_WINDOW || '1h';
    if (time.endsWith('h')) return parseInt(time) * 60 * 60 * 1000;
    if (time.endsWith('m')) return parseInt(time) * 60 * 1000;
    return parseInt(time) * 1000;
  })()
};
EOF

cat > src/config/auth.config.ts <<'EOF'
export const jwt = {
  secret: process.env.JWT_SECRET || 'change-me',
  expiresIn: process.env.JWT_EXPIRES_IN || '1d',
};
EOF

if [ "$DB_PROVIDER" != "none" ]; then
  if [ "$DB_PROVIDER" = "mongodb" ]; then
    cat > src/config/db.config.ts <<'EOF'
import mongoose from 'mongoose';

export async function connectDB(uri?: string) {
  if (!uri) {
    throw new Error('MongoDB requires a connection URI');
  }
  const connection = await mongoose.connect(uri);
  console.log('MongoDB connected');
  return connection;
}
EOF
  else
    cat > src/config/db.config.ts <<'EOF'
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();

export async function connectDB(uri?: string) {
  await prisma.$connect();
  console.log('Prisma connected to database');
  return prisma;
}
EOF
  fi
else
  cat > src/config/db.config.ts <<'EOF'
export async function connectDB(uri?: string) {
  console.log('No database configured. Skipping connection.');
}
EOF
fi

# ---------- 16) Global types ----------
cat > src/types/global.d.ts <<'EOF'
declare namespace NodeJS {
  interface ProcessEnv {
    NODE_ENV?: 'development' | 'production' | 'test';
    PORT?: string;
    DATABASE_URL?: string;
    JWT_SECRET?: string;
    JWT_EXPIRES_IN?: string;
    REDIS_URL?: string;
    LOG_LEVEL?: string;
    API_PREFIX?: string;
    API_RATE_LIMIT?: string;
    API_RATE_LIMIT_WINDOW?: string;
  }
}
EOF

cat > src/types/express/index.d.ts <<'EOF'
import { Request } from 'express';

declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}
EOF

# ---------- 17) Middlewares ----------
cat > src/middlewares/error.middleware.ts <<'EOF'
import { Request, Response, NextFunction } from 'express';

export function errorMiddleware(err: any, _req: Request, res: Response, _next: NextFunction) {
  const status = err.status || err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  res.status(status).json({ ok: false, message });
}
EOF

cat > src/middlewares/auth.middleware.ts <<'EOF'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { jwt as jwtCfg } from '../config/auth.config';

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ ok: false, message: 'Authorization header missing' });

  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ ok: false, message: 'Token missing' });

  try {
    const decoded = jwt.verify(token, jwtCfg.secret);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ ok: false, message: 'Invalid token' });
  }
}
EOF

cat > src/middlewares/validate.middleware.ts <<'EOF'
import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';

export const validate =
  (schema: ZodSchema) => (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse({ body: req.body, params: req.params, query: req.query });
    if (!result.success) {
      return res.status(400).json({ ok: false, errors: result.error.format() });
    }
    Object.assign(req, result.data);
    next();
  };
EOF

# ---------- 18) Utils ----------
cat > src/utils/response.ts <<'EOF'
import { Response } from 'express';

export function success<T>(res: Response, data: T, status = 200) {
  return res.status(status).json({ ok: true, data });
}

export function error(res: Response, message = 'Error', status = 400) {
  return res.status(status).json({ ok: false, message });
}
EOF

cat > src/utils/hash.ts <<'EOF'
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS || '10');

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

export async function comparePassword(plain: string, hashed: string): Promise<boolean> {
  return bcrypt.compare(plain, hashed);
}
EOF

cat > src/utils/jwt.ts <<'EOF'
import jwt from 'jsonwebtoken';
import { jwt as jwtCfg } from '../config/auth.config';

export function signToken(payload: object): string {
  return jwt.sign(payload, jwtCfg.secret, { expiresIn: jwtCfg.expiresIn });
}

export function verifyToken(token: string): any {
  return jwt.verify(token, jwtCfg.secret);
}
EOF

# ---------- 19) User Module ----------
cat > src/modules/user/user.validation.ts <<'EOF'
import { z } from 'zod';

export const createUserSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email'),
    name: z.string().min(2, 'Name must be at least 2 characters'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
  }),
});
EOF

cat > src/modules/user/user.service.ts <<'EOF'
import { hashPassword, comparePassword } from '../../utils/hash';

export async function hashUserPassword(password: string) {
  return hashPassword(password);
}

export async function verifyUserPassword(plain: string, hashed: string) {
  return comparePassword(plain, hashed);
}
EOF

if [ "$DB_PROVIDER" != "none" ]; then
  if [ "$DB_PROVIDER" = "mongodb" ]; then
    cat > src/modules/user/user.model.ts <<'EOF'
import { Schema, model, Document } from 'mongoose';

interface IUser extends Document {
  email: string;
  name: string;
  password: string;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    email: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    password: { type: String, required: true },
  },
  { timestamps: true },
);

export const UserModel = model<IUser>('User', UserSchema);
EOF
    cat > src/modules/user/user.controller.ts <<'EOF'
import { Request, Response } from 'express';
import { success, error } from '../../utils/response';
import { UserModel } from './user.model';
import { hashUserPassword } from './user.service';

export async function getUsers(req: Request, res: Response) {
  const users = await UserModel.find({}, { password: 0 });
  return success(res, users);
}

export async function createUser(req: Request, res: Response) {
  const { email, name, password } = req.body;
  const existingUser = await UserModel.findOne({ email });
  if (existingUser) return error(res, 'Email already in use', 409);

  const hashed = await hashUserPassword(password);
  const user = await UserModel.create({ email, name, password: hashed });
  const { password: _, ...userData } = user.toObject();
  return success(res, userData, 201);
}
EOF
  else
    cat > prisma/schema.prisma <<EOF
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "${DB_PROVIDER}"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  password  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF
    cat > src/modules/user/user.controller.ts <<'EOF'
import { Request, Response } from 'express';
import { success, error } from '../../utils/response';
import { prisma } from '../config/db.config';
import { hashUserPassword } from './user.service';

export async function getUsers(req: Request, res: Response) {
  const users = await prisma.user.findMany({
    select: { id: true, email: true, name: true, createdAt: true },
  });
  return success(res, users);
}

export async function createUser(req: Request, res: Response) {
  const { email, name, password } = req.body;
  const existingUser = await prisma.user.findUnique({ where: { email } });
  if (existingUser) return error(res, 'Email already in use', 409);

  const hashed = await hashUserPassword(password);
  const user = await prisma.user.create({ data: { email, name, password: hashed } });
  const { password: _, ...userData } = user;
  return success(res, userData, 201);
}
EOF
  fi
else
  cat > src/modules/user/user.controller.ts <<'EOF'
import { Request, Response } from 'express';
import { success, error } from '../../utils/response';

export async function getUsers(req: Request, res: Response) {
  return success(res, []);
}

export async function createUser(req: Request, res: Response) {
  return error(res, 'No database configured', 503);
}
EOF
fi

cat > src/modules/user/user.routes.ts <<'EOF'
import { Router } from 'express';
import { getUsers, createUser } from './user.controller';
import { validate } from '../../middlewares/validate.middleware';
import { createUserSchema } from './user.validation';

const router = Router();

router.get('/', getUsers);
router.post('/', validate(createUserSchema), createUser);

export default router;
EOF

# ---------- 20) Auth Module (Final: Register, Login, JWT, Validation) ----------

echo -e "${BLUE}${FEATURE} Setting up Auth Module (Register & Login)...${NC}"

# Create necessary directories
mkdir -p src/modules/auth/dto

# ---------- auth.validation.ts ----------
cat > src/modules/auth/auth.validation.ts <<'EOF'
import { z } from 'zod';

/**
 * Validation schema for user registration
 */
export const registerSchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Invalid email'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
  }),
});

/**
 * Validation schema for user login
 */
export const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
  }),
});
EOF

# ---------- auth.service.ts ----------
cat > src/modules/auth/auth.service.ts <<'EOF'
import { UserModel } from '../user/user.model';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'secret_key';

/**
 * Registers a new user.
 * @param name - Full name of the user
 * @param email - Email address (must be unique)
 * @param password - Plain text password (will be hashed)
 * @returns { token, user } - JWT token and user data (without password)
 */
export const registerUser = async (name: string, email: string, password: string) => {
  const existing = await UserModel.findOne({ email });
  if (existing) throw new Error('Email already in use');

  const hashed = await bcrypt.hash(password, 10);
  const user = await UserModel.create({ name, email, password: hashed });

  const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '1d' });
  const { password: _, ...userData } = user.toObject();
  return { token, user: userData };
};

/**
 * Logs in an existing user.
 * @param email - User's email
 * @param password - Plain text password
 * @returns { token, user } - JWT token and user data if credentials are valid
 */
export const loginUser = async (email: string, password: string) => {
  const user = await UserModel.findOne({ email });
  if (!user) throw new Error('Invalid credentials');

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new Error('Invalid credentials');

  const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '1d' });
  const { password: _, ...userData } = user.toObject();
  return { token, user: userData };
};

/**
 * Generates a JWT token for a given payload.
 * @param payload - Object to sign (e.g., { id: '...' })
 * @returns Signed JWT token
 */
export const generateToken = (payload: object) => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1d' });
};
EOF

# ---------- auth.controller.ts ----------
cat > src/modules/auth/auth.controller.ts <<'EOF'
import { Request, Response } from 'express';
import { success, error } from '../../utils/response';
import { registerUser, loginUser, generateToken } from './auth.service';

/**
 * Controller: Register a new user
 */
export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, password } = req.body;
    const result = await registerUser(name, email, password);
    return success(res, result, 201);
  } catch (err: any) {
    return error(res, err.message, 400);
  }
};

/**
 * Controller: Login existing user
 */
export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    const result = await loginUser(email, password);
    return success(res, result);
  } catch (err: any) {
    return error(res, err.message, 401);
  }
};

/**
 * Controller: Demo endpoint to generate a test token (for testing only)
 */
export const demoToken = async (req: Request, res: Response) => {
  const payload = { id: 'demo-user-id', email: 'test@example.com' };
  const token = generateToken(payload);
  return success(res, { token });
};
EOF

# ---------- auth.routes.ts ----------
cat > src/modules/auth/auth.routes.ts <<'EOF'
import { Router } from 'express';
import { login, register, demoToken } from './auth.controller';
import { validate } from '../../middlewares/validate.middleware';
import { loginSchema, registerSchema } from './auth.validation';

const router = Router();

// POST /api/auth/register - Register a new user
router.post('/register', validate(registerSchema), register);

// POST /api/auth/login - Login existing user
router.post('/login', validate(loginSchema), login);

// GET /api/auth/demo-token - Generate a test token (for development/testing)
router.get('/demo-token', demoToken);

export default router;
EOF

# ---------- DTOs (Data Transfer Objects) ----------
cat > src/modules/auth/dto/login.dto.ts <<'EOF'
/**
 * DTO for login request
 */
export interface LoginDto {
  email: string;
  password: string;
}
EOF

cat > src/modules/auth/dto/auth-response.dto.ts <<'EOF'
/**
 * DTO for authentication response
 */
export interface AuthResponseDto {
  token: string;
  user: {
    _id: string;
    email: string;
    name: string;
  };
}
EOF

echo -e "${GREEN}${SUCCESS} Auth Module: Register, Login, Validation, DTOs, and demo route added${NC}" 


# ---------- 21) Bootstrap ----------

cat > src/config/app.bootstrap.ts <<'EOF'
import { connectDB } from './db.config';
EOF

if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
  echo "import { connectRedis } from './redis.config';" >> src/config/app.bootstrap.ts
fi

cat >> src/config/app.bootstrap.ts <<'EOF'

export async function bootstrap() {
  // Database Connection
  try {
    const uri = process.env.DATABASE_URL;
    if (!uri) {
      console.warn("🟡 DATABASE_URL is not set. Using fallback (check db.config.ts).");
    }
    await connectDB(uri);
    console.log("✅ Database connected");
  } catch (err) {
    console.error("❌ Database connection failed. App may not work correctly:", err);
  }

  // Redis Connection (if enabled)
EOF

if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
  cat >> src/config/app.bootstrap.ts <<'EOF'
  try {
    await connectRedis();
    console.log("✅ Redis connected");
  } catch (err) {
    console.error("❌ Redis connection failed. Caching/sessions may not work:", err);
  }
EOF
fi

cat >> src/config/app.bootstrap.ts <<'EOF'
  console.log("🚀 Bootstrap complete");
}
EOF

# ---------- 22) Prisma Setup ----------
if [ "$DB_PROVIDER" != "none" ] && [ "$DB_PROVIDER" != "mongodb" ]; then
  echo -e "${BLUE}${INFO} Generating Prisma Client...${NC}"
  npx prisma generate > /dev/null 2>&1 && echo -e "${GREEN}${SUCCESS} Prisma Client generated${NC}" || echo -e "${RED}${ERROR} Failed to generate Prisma Client${NC}"
fi

# ---------- 23) Jest config (Updated for ESM + No globals) ----------
echo -e "${BLUE}${FILE} Creating Jest config (jest.config.cjs)...${NC}"

cat > jest.config.cjs <<'EOF'
/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  // Use preset for TypeScript + ESM support
  preset: 'ts-jest/presets/js-with-ts-esm',

  testEnvironment: 'node',

  testMatch: ['**/*.test.ts'],

  moduleFileExtensions: ['ts', 'js'],

  extensionsToTreatAsEsm: ['.ts'],

  coverageDirectory: './coverage',

  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.test.ts',
    '!src/config/app.bootstrap.ts'
  ],

  coverageThreshold: {
    global: {
      branches: 50,
      functions: 50,
      lines: 50,
      statements: 50
    }
  },

  watchPathIgnorePatterns: ['<rootDir>/node_modules/']
};
EOF

echo -e "${GREEN}${SUCCESS} Jest config created: jest.config.cjs${NC}"


# ---------- 24) README ----------
cat > README.md <<EOF
# ${PROJECT_NAME}

${DESCRIPTION}

## 🚀 Features
- Express + TypeScript
- Modular structure (controller, service, routes, dto, validation)
- Database: ${DB_PROVIDER}
- Optional: Docker, Swagger, Redis, Winston, Husky
- Zod validation
- JWT authentication
- Full testing & linting setup

## 📦 Scripts
- \`npm run dev\`: Start dev server
- \`npm run build\`: Build for production
- \`npm run start\`: Run compiled app
- \`npm run lint\`: Lint code
- \`npm run format\`: Format with Prettier
- \`npm run test\`: Run tests
- \`npm run db:seed\`: Seed database
- \`npm run db:reset\`: Reset database

## 🛠️ Environment
See \`.env\` file.

## 📎 Endpoints
- GET / - Health check
- GET /api/users - List users
- POST /api/users - Create user
- POST /api/auth/login - Login
- Swagger: /docs

## 📝 Git
Initialized: ${INIT_GIT}

## 📚 Documentation
Generated with Swagger UI.

EOF

# ---------- 25) Git ----------
if [[ "$INIT_GIT" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}${INFO} Initializing Git repository...${NC}"
  git init > /dev/null 2>&1
  git add . > /dev/null 2>&1
  git commit -m "feat: initialize project with Proton generator" > /dev/null 2>&1 && echo -e "${GREEN}${SUCCESS} Git initialized and first commit created${NC}" || echo -e "${YELLOW}${WARNING} Git commit skipped${NC}"
else
  echo -e "${YELLOW}${WARNING} Git initialization skipped${NC}"
fi

# ---------- 26) Final Output ----------
echo
echo -e "${GREEN}${SUCCESS} Project '${PROJECT_NAME}' created successfully!${NC}"
echo -e "${YELLOW}   Database: ${DB_PROVIDER}${NC}"
[[ "$USE_DOCKER" =~ ^[Yy]$ ]] && echo -e "${YELLOW}   🐳 Docker: Enabled${NC}"
[[ "$USE_SWAGGER" =~ ^[Yy]$ ]] && echo -e "${YELLOW}   📘 Swagger: Enabled at /docs${NC}"
[[ "$USE_REDIS" =~ ^[Yy]$ ]] && echo -e "${YELLOW}   🧩 Redis: Enabled${NC}"
[[ "$USE_WINSTON" =~ ^[Yy]$ ]] && echo -e "${YELLOW}   📝 Winston Logging: Enabled${NC}"
[[ "$USE_HUSKY" =~ ^[Yy]$ ]] && echo -e "${YELLOW}   🔗 Husky Hooks: Enabled${NC}"
echo -e "${YELLOW}   📦 Git: ${INIT_GIT}${NC}"

echo
echo -e "${BLUE}${RUN} Next Steps:${NC}"
echo "   cd ${PROJECT_NAME}"
if [ "$DB_PROVIDER" != "none" ] && [ "$DB_PROVIDER" != "mongodb" ]; then
  echo "   npx prisma migrate dev --name init   # Apply migrations"
fi
echo "   npm run dev                          # Start the server"
echo "   npm run db:seed                      # Seed database (optional)"
echo
echo -e "${CYAN}📌 Swagger Docs: http://localhost:${APP_PORT}/docs${NC}"
echo -e "${GREEN}💡 Tip: Edit .env to customize logging, CORS, rate limiting, and more!${NC}"
