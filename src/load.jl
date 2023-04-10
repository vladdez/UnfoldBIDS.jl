function BidsLayout(BIDSPath::AbstractString;
    derivative::Bool=true,
    specificFolder::Union{Nothing,AbstractString}=nothing,
    excludeFolder::Union{Nothing,AbstractString}=nothing,
    task::Union{Nothing,AbstractString}=nothing,
    run::Union{Nothing,AbstractString}=nothing)

    # Any files with these endings will be returned
    file_pattern = ["eeg", "set", "fif", "vhdr", "edf"]
    nPattern = 2

    # Extend file pattern
    if task === nothing
        @warn "No task provided, will load all tasks!!"
    else
        file_pattern = push!(file_pattern, "task-" * task)
        nPattern += 1
    end

    if run === nothing
        @warn "No run provided, will load all runs!!"
    else
        file_pattern = push!(file_pattern, "run-" * run)
        nPattern += 1
    end

    # Choose a specific folder in either ./ or ./derivatives
    if derivative && specificFolder !== nothing
        sPath = joinpath(BIDSPath, "derivatives", specificFolder)
        #@show sPath
    elseif specificFolder !== nothing
        sPath = joinpath(BIDSPath, specificFolder)
        #@show sPath
    end

    # Exclude these folders when using raw data
    if derivative && excludeFolder !== nothing
        exclude = excludeFolder
    elseif !derivative && excludeFolder !== nothing
        exclude = ["derivatives", excludeFolder]
    elseif !derivative
        exclude = "derivatives"
    else
        exclude = ""
    end


    files_df = DataFrame(subject=[], file=[], path=[])  # Initialize an empty DataFrame to hold results

    # Search for files matching file pattern
    if specificFolder !== nothing
        for (root, dirs, files) in walkdir(sPath)
            for file in files
                if sum(occursin.(file_pattern, file)) >= nPattern

                    sub_string = match(r"sub-\d{3}", file)
                    sub = last(sub_string.match, 3)
                    push!(files_df, (sub, file, root))
                end
            end
        end

    # When no specific folder is given look up whole Path    
    else
        for (root, dirs, files) in walkdir(BIDSPath)
            for file in files
                if sum(occursin.(file_pattern, file)) >= nPattern &&
                   (derivative && (exclude == "" || !any(occursin.(exclude, root))) ||
                    (!derivative && !any(occursin.(exclude, root))))

                    sub_string = match(r"sub-\d{3}", file)
                    sub = last(sub_string.match, 3)
                    push!(files_df, (sub, file, root))
                end
            end
        end
    end
    return files_df
end


#-----------------------------------------------------------------------------------------------
# Function loading BIDS data given BidsLayout DataFrame
function load_bids_eeg_data(layout_df)

	    # Initialize an empty dataframe
	    eeg_df = DataFrame()
	
	    # Loop through each EEG data file
	    for row in eachrow(layout_df)
			file_path = joinpath(row.path,row.file)
			@printf("Loading subject %s at:\n %s \n",row.subject, file_path)

	        # Read in the EEG data as a dataframe using the appropriate reader
	        if endswith(file_path, ".edf")
	            eeg_data = PyMNE.io.read_raw_edf(file_path, verbose="ERROR")
	        elseif endswith(file_path, ".vhdr")
	            eeg_data = PyMNE.io.read_raw_brainvision(file_path, verbose="ERROR")
	        elseif endswith(file_path, ".fif")
	            eeg_data = PyMNE.io.read_raw_fif(file_path, verbose="ERROR")
			elseif endswith(file_path, ".set")
				eeg_data = PyMNE.io.read_raw_eeglab(file_path, verbose="ERROR")
			end
	
			#############
			# TODO: Append specific subject data to dataframe
			#############
			# Add the EEG data to the main dataframe, along with subject and task information
	        #subject_id, task_id = match(r"sub-(.+)_task-(.*)_eeg", basename(file_path)).captures
	        #eeg_data.subject_id .= subject_id
	        #eeg_data.task_id .= task_id
	        tmp_df = DataFrame(subject = row.subject, data = eeg_data)

			append!(eeg_df, tmp_df)
	    end
	
	    # Return the combined EEG data dataframe
	    return eeg_df
	end
	

#-----------------------------------------------------------------------------------------------

# Function loading BIDS data directly by calling BidsLayout
#=function load_bids_eeg_data(BIDSPath::AbstractString;
							derivative::Bool=true,
							specificFolder::Union{Nothing,AbstractString}=nothing,
							excludeFolder::Union{Nothing,AbstractString}=nothing,
							task::Union{Nothing,AbstractString}=nothing,
							run::Union{Nothing,AbstractString}=nothing)

	    # Find all EEG data files in the BIDS directory
		layout_df = BidsLayout(BIDSPath=BIDSPath;
								derivative=derivative,
								specificFolder=specificFolder,
								excludeFolder=excludeFolder,
								task=task,
								run=run)
		
	    # Initialize an empty dataframe
	    eeg_df = DataFrame()
	
	    # Loop through each EEG data file
	    for row in eachrow(path_df)
			file_path = row.path *"/" * row.file
			
	        # Read in the EEG data as a dataframe using the appropriate reader
	        if endswith(file_path, ".edf")
	            eeg_data = PyMNE.io.read_raw_edf(file_path)
	        elseif endswith(file_path, ".vhdr")
	            eeg_data = PyMNE.io.read_raw_brainvision(file_path)
	        elseif endswith(file_path, ".fif")
	            eeg_data = PyMNE.io.read_raw_fif(file_path, verbose="ERROR")
			elseif endswith(file_path, ".set")
				eeg_data = PyMNE.io.read_raw_eeglab(file_path, verbose="ERROR")
			end
	
			#############
			# TODO: Append specific subject data to dataframe
			#############
			# Add the EEG data to the main dataframe, along with subject and task information
	        #subject_id, task_id = match(r"sub-(.+)_task-(.*)_eeg", basename(file_path)).captures
	        #eeg_data.subject_id .= subject_id
	        #eeg_data.task_id .= task_id
	        
			append!(eeg_df, eeg_data)
	    end
	
	    # Return the combined EEG data dataframe
	    #return eeg_df
	end
	=#