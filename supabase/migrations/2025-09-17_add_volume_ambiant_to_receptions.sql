-- Ajouter le champ volume_ambiant à la table receptions s'il n'existe pas
-- Migration idempotente pour corriger le problème des volumes dans les KPIs

-- A. Ajouter le champ volume_ambiant s'il n'existe pas
DO $$ 
BEGIN
    -- Vérifier si la colonne existe déjà
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'receptions' 
        AND column_name = 'volume_ambiant'
    ) THEN
        -- Ajouter la colonne
        ALTER TABLE public.receptions 
        ADD COLUMN volume_ambiant double precision;
        
        -- Calculer les valeurs pour les réceptions existantes
        UPDATE public.receptions 
        SET volume_ambiant = CASE 
            WHEN index_avant IS NOT NULL AND index_apres IS NOT NULL 
            THEN index_apres - index_avant 
            ELSE 0 
        END
        WHERE volume_ambiant IS NULL;
        
        RAISE NOTICE 'Colonne volume_ambiant ajoutée à la table receptions';
    ELSE
        RAISE NOTICE 'Colonne volume_ambiant existe déjà dans la table receptions';
    END IF;
END $$;

-- B. Ajouter le champ date_reception s'il n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'receptions' 
        AND column_name = 'date_reception'
    ) THEN
        ALTER TABLE public.receptions 
        ADD COLUMN date_reception date DEFAULT CURRENT_DATE;
        
        -- Mettre à jour les réceptions existantes avec la date de création
        UPDATE public.receptions 
        SET date_reception = created_at::date
        WHERE date_reception IS NULL;
        
        RAISE NOTICE 'Colonne date_reception ajoutée à la table receptions';
    ELSE
        RAISE NOTICE 'Colonne date_reception existe déjà dans la table receptions';
    END IF;
END $$;

-- C. Ajouter le champ statut s'il n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'receptions' 
        AND column_name = 'statut'
    ) THEN
        ALTER TABLE public.receptions 
        ADD COLUMN statut text DEFAULT 'validee' CHECK (statut IN ('validee', 'rejetee'));
        
        -- Mettre à jour les réceptions existantes
        UPDATE public.receptions 
        SET statut = 'validee'
        WHERE statut IS NULL;
        
        RAISE NOTICE 'Colonne statut ajoutée à la table receptions';
    ELSE
        RAISE NOTICE 'Colonne statut existe déjà dans la table receptions';
    END IF;
END $$;

-- D. Vérifier la structure finale
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'receptions'
ORDER BY ordinal_position;

