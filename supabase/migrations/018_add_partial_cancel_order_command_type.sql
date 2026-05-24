-- ============================================================================
-- Migration: 018_add_partial_cancel_order_command_type
--
-- Adds `partial_cancel_order` to command_type. Kept in its own migration so
-- the new enum label is committed before any function references it (Postgres
-- enum safety across migration boundaries).
-- ============================================================================

ALTER TYPE command_type ADD VALUE 'partial_cancel_order';
