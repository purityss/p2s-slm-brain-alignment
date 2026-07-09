% =========================================================
% Build both_neuron_pho_sem_index (for 254 P2S neurons)
% =========================================================
name = 'qwen2_audio';   

% ---- Known: b1:b2 are the 254 both (P2S-transfer) neurons ----
load([name, '_numeric_phonology_t.mat']);
Line_A = numeric_phonology_t;
load([name, '_numeric_semantics_t.mat']);
Line_B = numeric_semantics_t;

% Define indices
num_pho = 53285;
num_both = 1767;
num_sem = 14861;
p2 = num_pho;
b1 = p2 + 1;
b2 = p2 + num_both;
s1 = b2 + 1;
s2 = b2 + num_sem;

% =========================
% 1) Load start_both file
% =========================
start_file = [name, '_start_both_neurons_p.mat'];
S = load(start_file);
varname_start = [name, '_start_both_neurons_p'];

if isfield(S, varname_start)
    start_both = S.(varname_start);
else
    fn = fieldnames(S);
    start_both = S.(fn{1});
end

% =========================
% 2) Extract (layer, neuron) and force to double
% =========================
both_id_raw = start_both(:, 1:2);

% ---- Convert to numeric double matrix (254x2) ----
if istable(both_id_raw)
    both_id_raw = table2array(both_id_raw);
end

if iscell(both_id_raw)
    % Convert cell to double (supports numeric cells and numeric strings)
    both_id = nan(size(both_id_raw));
    for r = 1:size(both_id_raw, 1)
        for c = 1:size(both_id_raw, 2)
            v = both_id_raw{r, c};
            if isnumeric(v)
                both_id(r, c) = double(v);
            elseif isstring(v) || ischar(v)
                both_id(r, c) = str2double(v);
            else
                error('both_id contains unsupported type at row %d col %d.', r, c);
            end
            if isnan(both_id(r, c))
                error('both_id conversion failed (NaN) at row %d col %d. Value=%s', ...
                    r, c, string(v));
            end
        end
    end
else
    % Already numeric
    both_id = double(both_id_raw);
end

% =========================
% 3) Extract pho/sem indices (must be double 254x2)
% =========================
pho_idx = double(Line_A(b1:b2, 1:2));  % seg1/seg2 pho index
sem_idx = double(Line_B(b1:b2, 1:2));  % seg1/seg2 sem index

% =========================
% 4) Sanity check + concatenate
% =========================
if size(both_id, 1) ~= size(pho_idx, 1) || size(pho_idx, 1) ~= size(sem_idx, 1)
    error('Row mismatch: both_id(%d) pho_idx(%d) sem_idx(%d).', ...
        size(both_id, 1), size(pho_idx, 1), size(sem_idx, 1));
end

if size(both_id, 2) ~= 2 || size(pho_idx, 2) ~= 2 || size(sem_idx, 2) ~= 2
    error('Column mismatch. Expected: both_id=2 cols, pho_idx=2 cols, sem_idx=2 cols.');
end

both_neuron_pho_sem_index = [both_id, pho_idx, sem_idx];  % 254x6 double

% =========================
% 5) Save with prefix
% =========================
out_file = [name, '_both_neuron_pho_sem_index.mat'];
% Save only this variable with the specific name
save(out_file, 'both_neuron_pho_sem_index', '-v7');