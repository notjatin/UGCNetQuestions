-- =========================================================
-- ENUMS
-- =========================================================

CREATE TYPE question_type_enum AS ENUM (
    'mcq',
    'msq',
    'true_false',
    'numeric',
    'subjective'
);

CREATE TYPE question_status_enum AS ENUM (
    'draft',
    'published',
    'archived'
);

-- =========================================================
-- SUBJECTS
-- =========================================================

CREATE TABLE subjects (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL UNIQUE,
    slug            VARCHAR(255) UNIQUE,
    description     TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- TOPICS
-- supports hierarchy using parent_id
-- =========================================================

CREATE TABLE topics (
    id              BIGSERIAL PRIMARY KEY,
    subject_id      BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,

    parent_id       BIGINT REFERENCES topics(id) ON DELETE CASCADE,

    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255),

    description     TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_topics_subject_name
        UNIQUE(subject_id, name)
);

-- =========================================================
-- QUESTIONS
-- =========================================================

CREATE TABLE questions (
    id                  BIGSERIAL PRIMARY KEY,

    question_type       question_type_enum NOT NULL,

    question_text       TEXT NOT NULL,

    explanation         TEXT,
    solution_text       TEXT,

    difficulty_level    SMALLINT,

    marks               NUMERIC(5,2) DEFAULT 1,
    negative_marks      NUMERIC(5,2) DEFAULT 0,

    exam_year           SMALLINT,
    source              VARCHAR(500),

    language_code       VARCHAR(10) DEFAULT 'en',

    status              question_status_enum NOT NULL DEFAULT 'draft',

    created_by          BIGINT,
    updated_by          BIGINT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- QUESTION ↔ TOPIC MAPPING
-- many-to-many
-- =========================================================

CREATE TABLE question_topics (
    question_id     BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    topic_id        BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,

    PRIMARY KEY (question_id, topic_id)
);

-- =========================================================
-- QUESTION OPTIONS
-- =========================================================

CREATE TABLE question_options (
    id                  BIGSERIAL PRIMARY KEY,

    question_id         BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

    option_code         VARCHAR(10) NOT NULL,
    option_text         TEXT NOT NULL,

    sort_order          INTEGER NOT NULL DEFAULT 1,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_question_option_code
        UNIQUE(question_id, option_code)
);

-- =========================================================
-- CORRECT ANSWER MAPPING
-- supports both MCQ and MSQ
-- =========================================================

CREATE TABLE question_correct_options (
    question_id     BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

    option_id       BIGINT NOT NULL REFERENCES question_options(id) ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (question_id, option_id)
);

-- =========================================================
-- TESTS
-- =========================================================

CREATE TABLE tests (
    id                  BIGSERIAL PRIMARY KEY,

    title               VARCHAR(255) NOT NULL,

    description         TEXT,

    duration_minutes    INTEGER,

    total_marks         NUMERIC(7,2),

    is_published        BOOLEAN NOT NULL DEFAULT FALSE,

    created_by          BIGINT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- TEST QUESTIONS
-- =========================================================

CREATE TABLE test_questions (
    test_id             BIGINT NOT NULL REFERENCES tests(id) ON DELETE CASCADE,

    question_id         BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

    sort_order          INTEGER NOT NULL DEFAULT 1,

    marks               NUMERIC(5,2),
    negative_marks      NUMERIC(5,2),

    PRIMARY KEY (test_id, question_id)
);

-- =========================================================
-- ATTEMPTS
-- =========================================================

CREATE TABLE attempts (
    id                      BIGSERIAL PRIMARY KEY,

    test_id                 BIGINT NOT NULL REFERENCES tests(id) ON DELETE CASCADE,

    user_id                 BIGINT NOT NULL,

    started_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at            TIMESTAMPTZ,

    score                   NUMERIC(7,2),

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- ATTEMPT ANSWERS
-- supports MCQ + MSQ
-- =========================================================

CREATE TABLE attempt_answers (
    attempt_id          BIGINT NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,

    question_id         BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

    option_id           BIGINT NOT NULL REFERENCES question_options(id) ON DELETE CASCADE,

    is_selected         BOOLEAN NOT NULL DEFAULT TRUE,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (attempt_id, question_id, option_id)
);

-- =========================================================
-- QUESTION VERSIONING
-- =========================================================

CREATE TABLE question_versions (
    id                  BIGSERIAL PRIMARY KEY,

    question_id         BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

    version_number      INTEGER NOT NULL,

    question_snapshot   JSONB NOT NULL,

    created_by          BIGINT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_question_version
        UNIQUE(question_id, version_number)
);

-- =========================================================
-- INDEXES
-- =========================================================

CREATE INDEX idx_questions_question_type
    ON questions(question_type);

CREATE INDEX idx_questions_status
    ON questions(status);

CREATE INDEX idx_questions_exam_year
    ON questions(exam_year);

CREATE INDEX idx_question_options_question_id
    ON question_options(question_id);

CREATE INDEX idx_question_correct_options_question_id
    ON question_correct_options(question_id);

CREATE INDEX idx_question_topics_topic_id
    ON question_topics(topic_id);

CREATE INDEX idx_test_questions_sort_order
    ON test_questions(test_id, sort_order);

CREATE INDEX idx_attempts_user_id
    ON attempts(user_id);

CREATE INDEX idx_attempt_answers_question_id
    ON attempt_answers(question_id);

-- =========================================================
-- UPDATED_AT AUTO UPDATE FUNCTION
-- =========================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- UPDATED_AT TRIGGERS
-- =========================================================

CREATE TRIGGER trg_subjects_updated_at
BEFORE UPDATE ON subjects
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_topics_updated_at
BEFORE UPDATE ON topics
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_questions_updated_at
BEFORE UPDATE ON questions
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tests_updated_at
BEFORE UPDATE ON tests
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();