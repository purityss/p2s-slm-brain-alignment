function indices = find_consecutive_binary_sequences(binary_sequence, n)
    indices = [];
    
    in_sequence = false;
    sequence_length = 0;
    for i = 1:length(binary_sequence)
        if binary_sequence(i) == 1
            if ~in_sequence
                start_index = i;
                in_sequence = true;
            end
            sequence_length = sequence_length + 1;
        else
            if in_sequence
                if sequence_length >= n
                    end_index = i-1;
                    indices = [indices; [start_index, end_index]];
                end
                in_sequence = false;
                sequence_length = 0;
            end
        end
     end
    
    % 处理末尾情况
    if in_sequence && sequence_length >= n
        end_index = length(binary_sequence);
        indices = [indices; [start_index, end_index]];
    end
end