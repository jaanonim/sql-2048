CREATE FUNCTION get_key(k TEXT)
RETURNS TEXT language plpgsql AS $$
BEGIN
    RETURN 'No key handler! Key presed: "' || k || '"';
END
$$;
