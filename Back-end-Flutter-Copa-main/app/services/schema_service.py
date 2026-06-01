"""Pequena migracao defensiva para manter os dados separados por usuario."""

from app.database.connection import conectaBanco


TABELAS_COM_USUARIO = ("selecao", "jogador", "partidas")


def garantir_colunas_usuario() -> None:
    """Adiciona id_usuario_fk nas tabelas de dados, se ainda nao existir."""
    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        for tabela in TABELAS_COM_USUARIO:
            cursor.execute(
                """
                SELECT COUNT(*)
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = %s
                  AND COLUMN_NAME = 'id_usuario_fk';
                """,
                (tabela,),
            )
            existe = cursor.fetchone()[0] > 0
            if existe:
                continue

            cursor.execute(f"ALTER TABLE {tabela} ADD COLUMN id_usuario_fk INT NULL;")
            cursor.execute(f"CREATE INDEX idx_{tabela}_usuario ON {tabela} (id_usuario_fk);")
            cursor.execute(
                f"""
                ALTER TABLE {tabela}
                ADD CONSTRAINT fk_{tabela}_usuario
                FOREIGN KEY (id_usuario_fk) REFERENCES usuario (id_usuario)
                ON DELETE CASCADE;
                """
            )

        bd.commit()
    except Exception:
        bd.rollback()
        raise
    finally:
        bd.close()
