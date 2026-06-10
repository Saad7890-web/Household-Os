CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  email_normalized TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  email_verified_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE houses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'UTC',
  currency_code VARCHAR(3) NOT NULL DEFAULT 'USD',
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE house_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  membership_role TEXT NOT NULL CHECK (membership_role IN ('owner', 'admin', 'member', 'viewer')),
  membership_status TEXT NOT NULL DEFAULT 'active' CHECK (membership_status IN ('active', 'invited', 'removed', 'left')),
  joined_at TIMESTAMPTZ,
  left_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (house_id, user_id)
);

CREATE TABLE house_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  email_normalized TEXT NOT NULL,
  membership_role TEXT NOT NULL CHECK (membership_role IN ('admin', 'member', 'viewer')),
  token_hash CHAR(64) NOT NULL UNIQUE,
  invite_status TEXT NOT NULL DEFAULT 'pending' CHECK (invite_status IN ('pending', 'accepted', 'revoked', 'expired')),
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  accepted_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash CHAR(64) NOT NULL UNIQUE,
  device_name TEXT,
  user_agent TEXT,
  ip_address INET,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID REFERENCES houses(id) ON DELETE SET NULL,
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_houses_created_by_user_id ON houses(created_by_user_id);
CREATE INDEX idx_houses_deleted_at ON houses(deleted_at);

CREATE INDEX idx_house_members_house_id ON house_members(house_id);
CREATE INDEX idx_house_members_user_id ON house_members(user_id);
CREATE INDEX idx_house_members_active_house_user
  ON house_members(house_id, user_id)
  WHERE deleted_at IS NULL AND membership_status = 'active';

CREATE INDEX idx_house_invites_house_id ON house_invites(house_id);
CREATE INDEX idx_house_invites_email_normalized ON house_invites(email_normalized);
CREATE INDEX idx_house_invites_pending
  ON house_invites(house_id, email_normalized)
  WHERE invite_status = 'pending' AND revoked_at IS NULL AND accepted_at IS NULL;

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_active_user
  ON refresh_tokens(user_id, expires_at)
  WHERE revoked_at IS NULL;

CREATE INDEX idx_audit_logs_house_id_created_at ON audit_logs(house_id, created_at DESC);
CREATE INDEX idx_audit_logs_actor_user_id_created_at ON audit_logs(actor_user_id, created_at DESC);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_houses_set_updated_at
BEFORE UPDATE ON houses
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_house_members_set_updated_at
BEFORE UPDATE ON house_members
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_house_invites_set_updated_at
BEFORE UPDATE ON house_invites
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();